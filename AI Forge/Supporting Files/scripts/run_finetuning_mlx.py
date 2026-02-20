#!/usr/bin/env python3
"""
MLX Fine-Tuning Script for Apple Silicon

Optimized LoRA training using MLX framework on M-series Macs.
Includes aggressive memory management and GPU stability features.

Usage:
    python3 run_finetuning_mlx.py --model qwen2.5-coder --epochs 1 --low-memory
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Optional, Tuple

import yaml


def log_section(title: str):
    """Print a formatted section header."""
    print(f"\n{'=' * 70}")
    print(f"  {title}")
    print(f"{'=' * 70}\n")


def log_step(title: str):
    """Print a formatted step header."""
    print(f"\n{'-' * 70}")
    print(f"  {title}")
    print(f"{'-' * 70}\n")


def check_mlx_installed() -> bool:
    """Verify MLX is installed and working."""
    try:
        import mlx.core as mx
        print("✓ MLX is installed and accessible")
        return True
    except ImportError:
        print("✗ MLX is not installed")
        print("\nInstall MLX with:")
        print("  pip3 install --upgrade mlx mlx-lm")
        print("\nOr run setup script:")
        print("  python3 setup_mlx.py")
        return False


def check_model_available(model_name: str) -> bool:
    """Check if model is available on Hugging Face or can be downloaded."""
    print(f"Checking model availability: {model_name}...", end=" ", flush=True)
    
    # Check for Ollama-style names
    if ":" in model_name:
        print("✗")
        print(f"\n  Error: '{model_name}' looks like an Ollama model name.")
        print("  MLX fine-tuning requires a Hugging Face repo ID or a local path.")
        
        # Best-effort suggestions for common models
        suggestions = {
            "qwen2.5-coder": "Qwen/Qwen2.5-Coder-7B-Instruct",
            "llama3": "meta-llama/Meta-Llama-3-8B-Instruct",
            "mistral": "mistralai/Mistral-7B-Instruct-v0.1",
            "phi3": "microsoft/Phi-3-mini-4k-instruct"
        }
        
        base_name = model_name.split(":")[0].lower()
        if base_name in suggestions:
            print(f"\n  Did you mean: {suggestions[base_name]}?")
        
        return False

    try:
        from transformers import AutoTokenizer
        AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        print("✓")
        return True
    except Exception as e:
        print(f"✗\n  Error: {e}")
        return False


def prepare_mlx_dataset(
    input_path: Path,
    output_dir: Path,
    max_seq_length: int = 256
) -> Optional[Tuple[Path, Path]]:
    """
    Prepare dataset for MLX fine-tuning with optimized formatting.
    
    Args:
        input_path: JSONL file with instruction-tuning data
        output_dir: Directory for train.jsonl and valid.jsonl
        max_seq_length: Maximum sequence length in tokens
    
    Returns:
        Tuple of (train_path, valid_path) or None if failed
    """
    try:
        if not input_path.exists():
            print(f"✗ Dataset not found: {input_path}")
            return None
        
        print(f"Reading dataset: {input_path}...", end=" ", flush=True)
        
        examples = []
        with open(input_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        examples.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        
        if not examples:
            print(f"✗\nNo valid examples in dataset")
            return None
        
        print(f"✓ ({len(examples)} examples)")
        
        # Create output directory
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Split into train/validation (90/10)
        split_idx = int(len(examples) * 0.9)
        train_examples = examples[:split_idx]
        valid_examples = examples[split_idx:]
        
        # Ensure we have validation data
        if not valid_examples:
            valid_examples = train_examples[-max(1, len(train_examples) // 10):]
            train_examples = train_examples[:-max(1, len(train_examples) // 10)]
        
        # Write in MLX format
        train_path = output_dir / "train.jsonl"
        valid_path = output_dir / "valid.jsonl"
        
        print(f"Writing training data: {train_path}...", end=" ", flush=True)
        with open(train_path, 'w', encoding='utf-8') as f:
            for ex in train_examples:
                f.write(json.dumps(ex) + '\n')
        print(f"✓ ({len(train_examples)} examples)")
        
        print(f"Writing validation data: {valid_path}...", end=" ", flush=True)
        with open(valid_path, 'w', encoding='utf-8') as f:
            for ex in valid_examples:
                f.write(json.dumps(ex) + '\n')
        print(f"✓ ({len(valid_examples)} examples)")
        
        return (train_path, valid_path)
        
    except Exception as e:
        print(f"✗\nError preparing dataset: {e}")
        import traceback
        traceback.print_exc()
        return None


def run_mlx_training(
    model_name: str,
    data_dir: Path,
    output_dir: Path,
    config: dict
) -> bool:
    """
    Execute MLX LoRA fine-tuning with optimized parameters for M2.
    
    Args:
        model_name: HuggingFace model ID
        data_dir: Directory containing train.jsonl and valid.jsonl
        output_dir: Directory for adapter outputs
        config: Training configuration dict
    
    Returns:
        True if successful, False otherwise
    """
    
    log_step("MLX LoRA Fine-Tuning Configuration")
    
    print(f"Model: {model_name}")
    print(f"Batch size: {config['batch_size']}")
    print(f"Max sequence length: {config['max_seq_length']}")
    print(f"Learning rate: {config['learning_rate']}")
    print(f"Epochs: {config['epochs']}")
    print(f"LoRA rank: {config['lora_rank']}")
    print(f"LoRA alpha: {config['lora_alpha']}")
    print(f"LoRA dropout: {config['lora_dropout']:.2f}")
    
    if config.get('low_memory'):
        print("\n🔧 LOW-MEMORY MODE ENABLED:")
        print("  - Gradient checkpointing: ON")
        print("  - Reduced batch size for GPU stability")
    
    # Ensure adapter output directory exists
    adapter_dir = output_dir / "adapters"
    adapter_dir.mkdir(parents=True, exist_ok=True)
    
    # Compute LoRA scale from alpha and rank: scale = alpha / rank
    lora_scale = config['lora_alpha'] / config['lora_rank']
    
    # Build YAML config for LoRA parameters (not available as CLI flags)
    lora_yaml_config = {
        'lora_parameters': {
            'rank': config['lora_rank'],
            'dropout': config['lora_dropout'],
            'scale': lora_scale,
        },
    }
    
    # Write LoRA config to a temporary YAML file
    config_path = output_dir / "lora_config.yaml"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with open(config_path, 'w') as f:
        yaml.dump(lora_yaml_config, f, default_flow_style=False)
    print(f"\nLoRA config written to: {config_path}")
    
    # Build MLX training command
    # mlx_lm lora expects the data directory to contain train.jsonl and valid.jsonl
    cmd = [
        sys.executable, "-m", "mlx_lm", "lora",
        "--train",
        "--model", model_name,
        "--data", str(data_dir),
        "--adapter-path", str(adapter_dir),
        "--iters", str(config['total_iters']),
        "--steps-per-report", str(max(10, config['total_iters'] // 10)),
        "--steps-per-eval", str(max(10, config['total_iters'] // 10)),
        "--val-batches", str(max(10, config['total_iters'] // 20)),
        "--batch-size", str(config['batch_size']),
        "--learning-rate", str(config['learning_rate']),
        "--max-seq-length", str(config['max_seq_length']),
        "--config", str(config_path),
    ]
    
    # Add memory optimization flags
    if config.get('low_memory') or config['batch_size'] <= 1:
        cmd.append("--grad-checkpoint")
    
    print("\nCommand:")
    print(" ".join(cmd[:6]) + " \\")
    for arg in cmd[6:]:
        print(f"  {arg} \\")
    
    log_step("Running MLX Fine-Tuning")
    
    # Set optimized environment variables for Apple Silicon
    env = os.environ.copy()
    env['PYTHONUNBUFFERED'] = '1'
    env['MLX_GPU_MEMORY_FRACTION'] = '0.85'  # Conservative GPU memory use
    env['TOKENIZERS_PARALLELISM'] = '0'  # Avoid deadlocks
    
    # Run training
    try:
        result = subprocess.run(cmd, env=env, timeout=None)
        
        if result.returncode == 0:
            log_section("✓ Fine-Tuning Completed Successfully")
            print(f"\n📁 Adapters saved to: {adapter_dir}")
            print(f"\nNext steps:")
            print(f"  1. Use adapters for inference with MLX")
            print(f"  2. Run evaluation on test set")
            print(f"  3. Convert to Ollama format (optional)")
            return True
        else:
            log_section("✗ Fine-Tuning Failed")
            print(f"\nExit code: {result.returncode}")
            print("\n🔧 Troubleshooting tips:")
            print(f"\n1. GPU Memory Error?")
            print(f"   - Further reduce batch size: --batch-size 1")
            print(f"   - Reduce sequence length: --max-seq-length 128")
            print(f"   - Enable ultra-low-memory mode: --ultra-low-memory")
            print(f"\n2. Model Download Error?")
            print(f"   - Check internet connection")
            print(f"   - Verify model exists on Hugging Face: {model_name}")
            print(f"   - Try manual download: python3 -c \"from transformers import AutoTokenizer\"")
            print(f"\n3. Dataset Error?")
            print(f"   - Check {data_dir} contains train.jsonl and valid.jsonl")
            print(f"   - Verify JSONL format is correct")
            return False
            
    except KeyboardInterrupt:
        print("\n\n⚠️  Training cancelled by user")
        return False
    except Exception as e:
        log_section("✗ Unexpected Error")
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    parser = argparse.ArgumentParser(
        description="MLX LoRA Fine-Tuning for Apple Silicon",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Standard training (M2 with moderate dataset)
  python3 run_finetuning_mlx.py --model Qwen/Qwen2.5-Coder-7B-Instruct --epochs 1
  
  # Low memory mode (if getting GPU errors)
  python3 run_finetuning_mlx.py --model Qwen/Qwen2.5-Coder-7B-Instruct --low-memory
  
  # Ultra low memory (very tight constraints)
  python3 run_finetuning_mlx.py --model Qwen/Qwen2.5-Coder-7B-Instruct --ultra-low-memory
        """
    )
    
    parser.add_argument(
        "--model",
        required=True,
        help="HuggingFace model ID (e.g., Qwen/Qwen2.5-Coder-7B-Instruct)",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=1,
        help="Number of training epochs (default: 1)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=2,
        help="Batch size per device (default: 2, safe for M2)",
    )
    parser.add_argument(
        "--max-seq-length",
        type=int,
        default=256,
        help="Maximum sequence length (default: 256 tokens)",
    )
    parser.add_argument(
        "--learning-rate",
        type=float,
        default=5e-5,
        help="Learning rate (default: 5e-5)",
    )
    parser.add_argument(
        "--lora-rank",
        type=int,
        default=8,
        help="LoRA rank (default: 8)",
    )
    parser.add_argument(
        "--lora-alpha",
        type=int,
        default=32,
        help="LoRA alpha (default: 32)",
    )
    parser.add_argument(
        "--lora-dropout",
        type=float,
        default=0.05,
        help="LoRA dropout (default: 0.05)",
    )
    parser.add_argument(
        "--low-memory",
        action="store_true",
        help="Enable low-memory mode (batch_size=1, seq_length=256)",
    )
    parser.add_argument(
        "--ultra-low-memory",
        action="store_true",
        help="Ultra-low memory mode (batch_size=1, seq_length=128, gradient checkpointing)",
    )
    parser.add_argument(
        "--dataset",
        default="data/unified_train_dataset.jsonl",
        help="Path to training dataset (default: data/unified_train_dataset.jsonl)",
    )
    parser.add_argument(
        "--output-dir",
        default="models/",
        help="Output directory for adapters (default: models/)",
    )
    
    args = parser.parse_args()
    
    # Apply memory modes
    batch_size = args.batch_size
    max_seq = args.max_seq_length
    low_memory = args.low_memory
    
    if args.ultra_low_memory:
        batch_size = 1
        max_seq = 128
        low_memory = True
        print("⚠️  ULTRA-LOW-MEMORY MODE ENABLED\n")
    elif args.low_memory:
        batch_size = 1
        low_memory = True
        print("⚠️  LOW-MEMORY MODE ENABLED\n")
    
    log_section("MLX Fine-Tuning for Apple Silicon")
    
    # Verify MLX is installed
    log_step("Environment Check")
    if not check_mlx_installed():
        sys.exit(1)
    
    # Verify model is available
    if not check_model_available(args.model):
        print("\n✗ Model not found or invalid format. Make sure the model ID is correct.")
        print("MLX fine-tuning requires a Hugging Face repo ID or a local path.")
        print("\nExamples of valid Hugging Face models:")
        print("  - Qwen/Qwen2.5-Coder-7B-Instruct")
        print("  - mistralai/Mistral-7B-Instruct-v0.1")
        print("  - meta-llama/Llama-2-7b-hf")
        print("\nNote: Ollama-style names with ':' (e.g., 'qwen2.5-coder:7b') are NOT supported directly.")
        sys.exit(1)
    
    # Prepare dataset
    log_step("Dataset Preparation")
    dataset_path = Path(args.dataset)
    output_dir = Path(args.output_dir)
    data_dir = output_dir / "data"
    
    result = prepare_mlx_dataset(dataset_path, data_dir, max_seq_length=max_seq)
    if result is None:
        sys.exit(1)
    
    train_path, valid_path = result
    
    # Prepare training config
    log_step("Training Configuration")
    
    # Estimate iterations per epoch from training data
    try:
        with open(train_path, 'r') as f:
            num_samples = sum(1 for line in f if line.strip())
    except:
        num_samples = 1000  # Conservative estimate
    
    iters_per_epoch = max(10, (num_samples + batch_size - 1) // batch_size)
    total_iters = iters_per_epoch * args.epochs
    
    config = {
        'batch_size': batch_size,
        'max_seq_length': max_seq,
        'learning_rate': args.learning_rate,
        'epochs': args.epochs,
        'total_iters': total_iters,
        'lora_rank': args.lora_rank,
        'lora_alpha': args.lora_alpha,
        'lora_dropout': args.lora_dropout,
        'low_memory': low_memory,
    }
    
    print(f"Training samples: {num_samples}")
    print(f"Iterations per epoch: {iters_per_epoch}")
    
    # Run training
    success = run_mlx_training(args.model, data_dir, output_dir, config)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
