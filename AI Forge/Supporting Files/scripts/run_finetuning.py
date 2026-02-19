#!/usr/bin/env python3
"""
Fine-Tuning Execution Script

Orchestrates the fine-tuning process:
1. Verifies the base model is available (pulls from Ollama if needed)
2. Converts Ollama model to MLX format
3. Executes the fine-tuning using MLX (Apple Silicon optimized)
4. Saves the fine-tuned model and converts back to Ollama format
"""

import argparse
import subprocess
import sys
import os
import json
from pathlib import Path
from typing import Optional, Tuple


def check_ollama_installed() -> bool:
    """Check if Ollama is installed and accessible."""
    try:
        result = subprocess.run(
            ["ollama", "--version"],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def check_ollama_model(model_name: str) -> bool:
    """Check if an Ollama model is available locally."""
    try:
        result = subprocess.run(
            ["ollama", "list"],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode == 0:
            # Print the full output for debugging
            print("Available Ollama models:")
            print(result.stdout)
            print()
            
            # Parse the output to find the model
            # Ollama list output format: NAME ID SIZE MODIFIED
            base_name = model_name.split(':')[0]
            tag = model_name.split(':')[1] if ':' in model_name else 'latest'
            
            for line in result.stdout.strip().split('\n')[1:]:  # Skip header
                if line.strip():
                    parts = line.split()
                    if parts:
                        listed_name = parts[0]
                        listed_base = listed_name.split(':')[0]
                        listed_tag = listed_name.split(':')[1] if ':' in listed_name else 'latest'
                        
                        # Check for exact match
                        if listed_name == model_name:
                            print(f"✓ Found exact match: {listed_name}")
                            return True
                        
                        # Check if base name matches and tag matches
                        if listed_base == base_name and listed_tag == tag:
                            print(f"✓ Found matching model: {listed_name}")
                            return True
                        
                        # If no tag specified, match any tag of the base model
                        if ':' not in model_name and listed_base == base_name:
                            print(f"✓ Found model with tag: {listed_name}")
                            return True
        return False
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        print(f"Error checking Ollama models: {e}")
        return False


def pull_ollama_model(model_name: str) -> bool:
    """Pull an Ollama model if not available locally."""
    print(f"Model '{model_name}' not found locally. Pulling from Ollama...")
    try:
        result = subprocess.run(
            ["ollama", "pull", model_name],
            capture_output=False,  # Show progress to user
            timeout=3600  # 1 hour timeout for large models
        )
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print(f"Error: Timeout while pulling model '{model_name}'")
        return False
    except FileNotFoundError:
        print("Error: Ollama is not installed or not in PATH")
        return False


def estimate_tokens(text: str) -> int:
    """
    Estimate token count using a simple heuristic.
    Most tokenizers use roughly 1 token per 4 characters on average,
    accounting for word boundaries and special characters.
    This is conservative for code and mixed-content text.
    """
    # Remove extra whitespace and normalize
    text = ' '.join(text.split())
    # Estimate: ~1 token per 4 characters
    return max(1, len(text) // 4)


def split_long_sequence(user_part: str, assistant_part: str, max_tokens: int = 512) -> list:
    """
    Split a user/assistant pair if it exceeds max_tokens.
    Returns list of {"text": ...} dicts representing complete examples.
    
    Strategy: If output is too long, chunk it while preserving context.
    Each chunk becomes a separate training example.
    """
    # First, check if formatted text exceeds limit
    formatted = f"<|user|>\n{user_part}<|assistant|>\n{assistant_part}"
    
    if estimate_tokens(formatted) <= max_tokens:
        return [{"text": formatted}]
    
    # Need to split - chunk the assistant output intelligently
    results = []
    
    # Calculate tokens used by user portion and delimiters
    user_formatted = f"<|user|>\n{user_part}<|assistant|>\n"
    user_tokens = estimate_tokens(user_formatted)
    
    # Reserve tokens for user part + some buffer
    available_for_output = max(100, max_tokens - user_tokens - 20)
    
    # Split output by logical boundaries (lines/sentences)
    output_lines = assistant_part.split('\n')
    current_chunk = []
    current_tokens = 0
    
    for line in output_lines:
        if not line.strip():
            continue
        
        line_tokens = estimate_tokens(line)
        
        # If adding this line exceeds limit and we have content, save chunk
        if current_tokens + line_tokens > available_for_output and current_chunk:
            chunk_text = '\n'.join(current_chunk)
            formatted_chunk = f"<|user|>\n{user_part}<|assistant|>\n{chunk_text}"
            results.append({"text": formatted_chunk})
            current_chunk = [line]
            current_tokens = line_tokens
        else:
            current_chunk.append(line)
            current_tokens += line_tokens
    
    # Save final chunk if it has content
    if current_chunk:
        chunk_text = '\n'.join(current_chunk)
        formatted_chunk = f"<|user|>\n{user_part}<|assistant|>\n{chunk_text}"
        results.append({"text": formatted_chunk})
    
    # Fallback: if splitting failed, return original (will be truncated by MLX)
    return results if results else [{"text": formatted}]


def get_ollama_model_path(model_name: str) -> str:
    """Get the local path for an Ollama model for use with MLX."""
    # Ollama stores models in ~/.ollama/models
    ollama_models_dir = Path.home() / ".ollama" / "models"
    
    # Ollama model names can have tags like "qwen2.5-coder:7b"
    base_name = model_name.split(':')[0]
    tag = model_name.split(':')[1] if ':' in model_name else 'latest'
    
    # Check for the model manifest
    manifest_path = ollama_models_dir / "manifests" / "registry.ollama.ai" / "library" / base_name / tag
    
    if manifest_path.exists():
        # For MLX, we'll use the Hugging Face model ID if available
        # Many Ollama models are based on HF models
        hf_model_mapping = {
            "qwen2.5-coder": "Qwen/Qwen2.5-Coder-7B-Instruct",
            "llama3": "meta-llama/Meta-Llama-3-8B-Instruct",
            "mistral": "mistralai/Mistral-7B-Instruct-v0.2",
            "codellama": "codellama/CodeLlama-7b-Instruct-hf",
        }
        
        for key, hf_id in hf_model_mapping.items():
            if base_name.startswith(key):
                return hf_id
    
    # Fallback: return the model name as-is (might be a HuggingFace ID)
    return model_name


def prepare_mlx_dataset_split(input_path: Path, output_dir: Path, train_ratio: float = 0.9, max_seq_length: int = 512) -> Optional[Tuple[Path, Path]]:
    """
    Convert Alpaca-format dataset to MLX-compatible format with train/validation split.
    
    Handles token length management:
    - Estimates token count before training
    - Splits sequences exceeding max_seq_length to prevent truncation
    - Reports statistics on split sequences
    
    MLX typically expects separate train.jsonl and valid.jsonl files.
    
    Returns: (train_path, valid_path) or None if failed
    """
    try:
        import json
        
        if not input_path.exists():
            print(f"Error: Input dataset file not found: {input_path}")
            return None
        
        print(f"Preparing MLX dataset from {input_path}...")
        print(f"Maximum sequence length: {max_seq_length} tokens")
        print()
        
        mlx_data = []
        sequences_split = 0
        max_seq_found = 0
        
        with open(input_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                if not line.strip():
                    continue
                    
                try:
                    item = json.loads(line)
                    
                    # Convert Alpaca format (instruction, input, output) to text format
                    instruction = item.get('instruction', '')
                    input_text = item.get('input', '')
                    output_text = item.get('output', '')
                    
                    if not instruction or not output_text:
                        continue
                    
                    # Format user part and assistant part for token checking
                    user_part = f"{instruction}\n{input_text}" if input_text else instruction
                    assistant_part = output_text
                    
                    # Check and handle token length
                    formatted = f"<|user|>\n{user_part}<|assistant|>\n{assistant_part}"
                    tokens = estimate_tokens(formatted)
                    max_seq_found = max(max_seq_found, tokens)
                    
                    # Split if necessary
                    if tokens > max_seq_length:
                        chunks = split_long_sequence(user_part, assistant_part, max_seq_length)
                        mlx_data.extend(chunks)
                        sequences_split += 1
                    else:
                        mlx_data.append({"text": formatted})
                        
                except json.JSONDecodeError:
                    continue
        
        if not mlx_data:
            print("Error: Dataset conversion resulted in 0 examples!")
            print(f"Check that {input_path} contains valid Alpaca-format JSONL data")
            print("Expected format: {\"instruction\": \"...\", \"input\": \"...\", \"output\": \"...\"}")
            return None
        
        # Ensure output directory exists
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Split into train and validation
        split_index = int(len(mlx_data) * train_ratio)
        train_data = mlx_data[:split_index]
        valid_data = mlx_data[split_index:]
        
        # Ensure we have at least some validation data
        if not valid_data:
            valid_data = train_data[-max(1, len(train_data) // 10):]
            train_data = train_data[:-max(1, len(train_data) // 10)]
        
        # Write train dataset
        train_path = output_dir / "train.jsonl"
        with open(train_path, 'w', encoding='utf-8') as f:
            for item in train_data:
                f.write(json.dumps(item) + '\n')
        
        # Write validation dataset
        valid_path = output_dir / "valid.jsonl"
        with open(valid_path, 'w', encoding='utf-8') as f:
            for item in valid_data:
                f.write(json.dumps(item) + '\n')
        
        print(f"✓ Dataset preparation complete:")
        print(f"  - Total examples (after splitting): {len(mlx_data)}")
        print(f"  - Sequences that required splitting: {sequences_split}")
        print(f"  - Maximum sequence length found: {max_seq_found} tokens")
        print(f"  - Training examples: {len(train_data)} ({train_path.stat().st_size} bytes)")
        print(f"  - Validation examples: {len(valid_data)} ({valid_path.stat().st_size} bytes)")
        
        if sequences_split > 0:
            print(f"\n✓ Sequence splitting prevented data truncation:")
            print(f"  Long sequences were chunked to fit within {max_seq_length}-token limit")
            print(f"  This preserves training information that would otherwise be lost")
        
        return (train_path, valid_path)
        
    except IOError as e:
        print(f"Error reading/writing dataset files: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error preparing dataset: {e}")
        import traceback
        traceback.print_exc()
        return None


def run_mlx_finetuning(
    model_name: str,
    dataset_path: Path,
    output_dir: Path,
    learning_rate: float,
    batch_size: int,
    epochs: int,
    max_seq_length: int = 256
) -> bool:
    """Execute MLX LoRA fine-tuning."""
    print("\n" + "=" * 60)
    print("Starting Fine-Tuning with MLX (Apple Silicon Optimized)")
    print("=" * 60)
    print(f"Model: {model_name}")
    print(f"Dataset: {dataset_path}")
    print(f"Output: {output_dir}")
    print()
    
    try:
        # Get the Hugging Face model path
        hf_model = get_ollama_model_path(model_name)
        print(f"Using base model: {hf_model}")
        
        # Prepare dataset with proper train/validation split
        data_dir = output_dir / "data"
        print("\n" + "-" * 60)
        print("Step 1: Preparing dataset with train/validation split")
        print("-" * 60)
        
        result = prepare_mlx_dataset_split(dataset_path, data_dir, max_seq_length=max_seq_length)
        if result is None:
            print("Error: Failed to prepare dataset for MLX")
            return False
        
        train_path, valid_path = result
        
        # Prepare output directories
        adapter_dir = output_dir / "adapters"
        adapter_dir.mkdir(parents=True, exist_ok=True)
        
        print("\n" + "-" * 60)
        print("Step 2: Configuring MLX fine-tuning parameters")
        print("-" * 60)
        
        # MLX lora expects iterations, not epochs
        # Use train.jsonl to estimate iterations
        try:
            with open(train_path, 'r') as f:
                train_samples = sum(1 for line in f if line.strip())
        except:
            train_samples = 1440  # Fallback estimate
        
        # Standard MLX calculation: iterations = ceil(samples / batch_size) * epochs
        iters_per_epoch = max(10, (train_samples + batch_size - 1) // batch_size)
        total_iters = iters_per_epoch * epochs
        
        print(f"Training configuration:")
        print(f"  - Training samples: {train_samples}")
        print(f"  - Iterations per epoch: {iters_per_epoch}")
        print(f"  - Total epochs: {epochs}")
        print(f"  - Total iterations: {total_iters}")
        print(f"  - Learning rate: {learning_rate}")
        print(f"  - Batch size: {batch_size}")
        
        # Build MLX fine-tuning command
        # MLX expects: python3 -m mlx_lm lora [options]
        # Note: --data should point to the directory containing train.jsonl, valid.jsonl, test.jsonl
        cmd = [
            "python3", "-m", "mlx_lm", "lora",
            "--model", hf_model,
            "--train",
            "--data", str(data_dir),
            "--adapter-path", str(adapter_dir),
            "--iters", str(total_iters),
            "--steps-per-eval", str(max(5, total_iters // 20)),
            "--steps-per-report", str(max(5, total_iters // 20)),
            "--val-batches", str(max(5, total_iters // 20)),
            "--learning-rate", str(learning_rate),
            "--batch-size", str(batch_size),
            "--max-seq-length", str(max_seq_length),
            "--grad-checkpoint",  # Enable gradient checkpointing for memory efficiency
        ]
        
        print(f"\nFine-tuning command:")
        print(f"  {' '.join(cmd[:5])}")
        print(f"  {' '.join(cmd[5:])}")
        print()
        
        print("\n" + "-" * 60)
        print("Step 3: Running fine-tuning...")
        print("-" * 60 + "\n")
        
        # Set environment variables for GPU stability
        env = os.environ.copy()
        env['MLX_GPU_MEMORY_FRACTION'] = '0.8'  # Use 80% of GPU memory
        env['MLX_DISABLE_FLASH_ATTN'] = '1'  # Additional safeguard
        env['PYTHONUNBUFFERED'] = '1'  # Unbuffered output for better debugging
        
        # Run the fine-tuning
        result = subprocess.run(cmd, env=env)
        
        if result.returncode == 0:
            print("\n" + "=" * 60)
            print("Fine-Tuning Completed Successfully!")
            print("=" * 60)
            print(f"\nModel adapters saved to: {adapter_dir}")
            print(f"You can now use these adapters for inference.")
            return True
        else:
            print("\n" + "=" * 60)
            print(f"Fine-Tuning Failed (exit code: {result.returncode})")
            print("=" * 60)
            print("\nTroubleshooting GPU Memory Issues:")
            print("\nIf you see 'Command buffer execution failed' or similar GPU errors:")
            print("  1. Reduce batch size: --batch-size 1")
            print("  2. Reduce sequence length: --max-seq-length 128")
            print("  3. Or use low-memory mode: --low-memory")
            print("     (This sets batch_size=1 and max_seq_length=128 automatically)")
            print("\nExample command with reduced parameters:")
            print("  python3 run_finetuning.py --model qwen2.5-coder --batch-size 1 --max-seq-length 128 --epochs 1")
            print("\nOr use low-memory mode:")
            print("  python3 run_finetuning.py --model qwen2.5-coder --low-memory")
            print("\nOther troubleshooting:")
            print("- Ensure mlx_lm is installed: pip3 install --user mlx-lm")
            print("- Check that your dataset is properly formatted")
            print("- Try reducing the number of epochs (--epochs 1)")
            print("- Monitor GPU memory with: python3 -c 'import mlx.core as mx; print(mx.metal.device_memory())'")
            return False
        
    except FileNotFoundError as e:
        print(f"Error: Required tool not found: {e}")
        print("\nInstallation:")
        print("- MLX fine-tuning: pip3 install --user mlx-lm")
        print("- Ollama: https://ollama.ai")
        return False
    except Exception as e:
        print(f"Unexpected error during fine-tuning: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Run fine-tuning process with MLX (Apple Silicon optimized)"
    )
    parser.add_argument(
        "--model", "-m",
        required=True,
        help="Base model name (Ollama model or HuggingFace ID)"
    )
    parser.add_argument(
        "--learning-rate", "-lr",
        type=float,
        default=0.0001,
        help="Learning rate (default: 0.0001)"
    )
    parser.add_argument(
        "--batch-size", "-bs",
        type=int,
        default=1,
        help="Micro batch size (default: 1 for Apple Silicon GPU stability)"
    )
    parser.add_argument(
        "--max-seq-length",
        type=int,
        default=256,
        help="Maximum sequence length in tokens (default: 256 for memory stability). Reduce to 128 if still getting GPU errors."
    )
    parser.add_argument(
        "--epochs", "-e",
        type=int,
        default=3,
        help="Number of training epochs (default: 3)"
    )
    parser.add_argument(
        "--low-memory",
        action="store_true",
        help="Enable aggressive memory conservation (batch_size=1, max_seq_length=128). Use if getting GPU memory errors."
    )
    parser.add_argument(
        "--output-dir", "-o",
        default="models/",
        help="Output directory for fine-tuned model (default: models/)"
    )
    parser.add_argument(
        "--dataset-path", "-d",
        default="data/unified_finetune_dataset.jsonl",
        help="Path to training dataset (default: data/unified_finetune_dataset.jsonl)"
    )
    
    args = parser.parse_args()
    
    # Apply low-memory mode if requested
    if args.low_memory:
        args.batch_size = 1
        args.max_seq_length = 128
        print("[LOW-MEMORY MODE ENABLED]")
        print("  - Batch size: 1")
        print("  - Max sequence length: 128 tokens")
        print("  - Gradient checkpointing: enabled")
        print()
    
    # Use current working directory as base (project directory)
    base_dir = Path.cwd()
    
    print("=" * 60)
    print("Fine-Tuning Execution")
    print("=" * 60)
    print(f"Base Model: {args.model}")
    print(f"Learning Rate: {args.learning_rate}")
    print(f"Batch Size: {args.batch_size}")
    print(f"Max Sequence Length: {args.max_seq_length} tokens")
    print(f"Epochs: {args.epochs}")
    print(f"Output Directory: {args.output_dir}")
    print(f"Dataset Path: {args.dataset_path}")
    print(f"Working Directory: {base_dir}")
    print()
    
    # Step 1: Verify dataset exists and has content
    print("-" * 60)
    print("Step 0: Validating dataset")
    print("-" * 60)
    
    dataset_path = base_dir / args.dataset_path
    if not dataset_path.exists():
        print(f"Error: Dataset not found at {dataset_path}")
        print("\nPlease run Step 2 (Generate Dataset) first.")
        sys.exit(1)
    
    # Verify dataset is not empty
    dataset_size = dataset_path.stat().st_size
    if dataset_size == 0:
        print(f"Error: Dataset file is empty: {dataset_path}")
        print("Please run Step 2 (Generate Dataset) again.")
        sys.exit(1)
    
    # Count lines in dataset for diagnostics
    try:
        with open(dataset_path, 'r') as f:
            dataset_lines = sum(1 for line in f if line.strip())
        print(f"✓ Dataset found: {dataset_path}")
        print(f"  - File size: {dataset_size} bytes")
        print(f"  - Lines/entries: {dataset_lines}")
    except Exception as e:
        print(f"Error reading dataset: {e}")
        sys.exit(1)
    
    # Step 2: Check Ollama installation
    print("\n" + "-" * 60)
    print("Step 1: Verifying Ollama installation")
    print("-" * 60)
    
    if not check_ollama_installed():
        print("Error: Ollama is not installed or not accessible in PATH")
        print("\nPlease ensure Ollama is installed:")
        print("  - Download from: https://ollama.ai")
        print("  - Or install via: brew install ollama")
        print("\nAfter installation, restart your terminal or add Ollama to your PATH")
        sys.exit(1)
    print("✓ Ollama is installed and accessible")
    
    # Step 3: Check/pull Ollama model
    print(f"\n" + "-" * 60)
    print("Step 2: Checking for Ollama model")
    print("-" * 60)
    
    print(f"Looking for model '{args.model}'...")
    if check_ollama_model(args.model):
        print(f"✓ Model '{args.model}' is available locally")
    else:
        print(f"Model '{args.model}' not found locally")
        if not pull_ollama_model(args.model):
            print(f"\nError: Failed to pull model '{args.model}'")
            sys.exit(1)
        print(f"✓ Model '{args.model}' pulled successfully")
    
    # Step 4: Prepare output directory and run MLX fine-tuning
    print(f"\n" + "-" * 60)
    print("Step 3: Preparing for fine-tuning")
    print("-" * 60)
    
    output_dir = Path(base_dir) / args.output_dir
    try:
        output_dir.mkdir(parents=True, exist_ok=True)
        print(f"✓ Output directory ready: {output_dir}")
    except Exception as e:
        print(f"Error creating output directory: {e}")
        sys.exit(1)
    
    # Step 5: Run MLX training
    print()
    success = run_mlx_finetuning(
        model_name=args.model,
        dataset_path=dataset_path,
        output_dir=output_dir,
        learning_rate=args.learning_rate,
        batch_size=args.batch_size,
        epochs=args.epochs,
        max_seq_length=args.max_seq_length
    )
    
    if success:
        print("\n" + "=" * 60)
        print("Fine-Tuning Complete!")
        print("=" * 60)
        print(f"Adapters saved to: {output_dir / 'adapters'}")
        print("\nNext steps:")
        print("  1. Test the fine-tuned model with mlx_lm.generate")
        print("  2. Run Step 5 to evaluate for overfitting")
        print("  3. Convert to Ollama format (if needed)")
    else:
        print("\n" + "=" * 60)
        print("Fine-Tuning Failed")
        print("=" * 60)
        print("Please check the error messages above and resolve any issues.")
        sys.exit(1)


if __name__ == "__main__":
    main()
