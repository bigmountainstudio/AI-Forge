# MLX Fine-Tuning Guide for Apple Silicon

## Overview

MLX is Apple's machine learning framework specifically designed for Apple Silicon (M-series chips). It's significantly more memory-efficient than Axolotl for fine-tuning on Mac hardware.

### Why MLX for M2?

- **Memory Efficient**: ~40-60% less VRAM than Axolotl
- **Native Metal Acceleration**: Optimized for Apple Silicon GPU
- **Minimal Overhead**: No CUDA bloat
- **Proven for 7B Models**: Easily handles 7B parameter models on 64GB RAM

---

## Installation

### 1. Setup MLX Environment

Run the automated setup script:

```bash
cd "AI Forge/Supporting Files/scripts"
python3 setup_mlx.py
```

This will:
- Verify Python 3.9+
- Install MLX, MLX-LM, and dependencies
- Test Metal acceleration on your device

### 2. Manual Installation (if needed)

```bash
pip3 install --upgrade mlx mlx-lm transformers
```

### 3. Verify Installation

```bash
python3 -c "import mlx.core as mx; print('MLX OK')"
```

---

## Quick Start

### Basic Command

```bash
cd "AI Forge/Supporting Files/scripts"
python3 run_finetuning_mlx.py \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --epochs 1
```

### For M2 with 64GB RAM (Aggressive)

```bash
python3 run_finetuning_mlx.py \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --epochs 3 \
  --batch-size 2
```

### If You Get GPU Memory Errors

**Option 1: Low-Memory Mode**
```bash
python3 run_finetuning_mlx.py \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --low-memory \
  --epochs 1
```

**Option 2: Ultra-Low-Memory Mode**
```bash
python3 run_finetuning_mlx.py \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --ultra-low-memory \
  --epochs 1
```

---

## Configuration Parameters

### Model Selection

Most compatible models for 7B fine-tuning:

```bash
# Qwen (Recommended for code)
--model Qwen/Qwen2.5-Coder-7B-Instruct

# Mistral (Fast)
--model mistralai/Mistral-7B-Instruct-v0.1

# Llama 2
--model meta-llama/Llama-2-7b-hf

# Code Llama
--model codellama/CodeLlama-7b-Instruct-hf
```

### Training Parameters

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| `--epochs` | 1 | 1-5 | Number of full passes through data |
| `--batch-size` | 2 | 1-4 | Samples per gradient step; 1 if OOM |
| `--max-seq-length` | 256 | 128-512 | Max tokens per example |
| `--learning-rate` | 5e-5 | 1e-5 to 1e-4 | Typically 5e-5 works well |
| `--lora-rank` | 8 | 4-32 | LoRA parameter count; 8 is standard |
| `--lora-alpha` | 32 | 16-64 | LoRA scaling; usually 4x rank |
| `--lora-dropout` | 0.05 | 0.0-0.1 | Dropout in LoRA layers |

### Dataset Path

```bash
# Default (from unified dataset generation)
--dataset data/unified_train_dataset.jsonl

# Custom path
--dataset /path/to/your/dataset.jsonl
```

### Output Directory

```bash
# Default
--output-dir models/

# Custom
--output-dir /path/to/output/
```

---

## Memory Management

### Understanding Memory Modes

**Standard Mode (batch_size=2, seq_length=256)**
- Best: Datasets < 50k examples, 64GB+ RAM
- Fastest training
- Command: Normal execution (see Quick Start)

**Low-Memory Mode (batch_size=1, seq_length=256)**
- Best: Datasets 50k-100k examples, 32GB-64GB RAM
- Slower but manageable
- Command: Add `--low-memory`

**Ultra-Low-Memory Mode (batch_size=1, seq_length=128)**
- Best: Memory-constrained or large datasets
- Slowest but most stable
- Command: Add `--ultra-low-memory`

### Troubleshooting OOM Errors

If you see "Command buffer execution failed" or GPU memory errors:

1. **First attempt** → Use `--low-memory`
   ```bash
   python3 run_finetuning_mlx.py --model ... --low-memory
   ```

2. **Still failing** → Use `--ultra-low-memory`
   ```bash
   python3 run_finetuning_mlx.py --model ... --ultra-low-memory
   ```

3. **Still failing** → Reduce learning rate and use smaller model
   ```bash
   python3 run_finetuning_mlx.py --model ... --ultra-low-memory --learning-rate 1e-5
   ```

### Monitoring GPU Memory

While training is running, in another terminal:

```bash
python3 -c "
import mlx.core as mx
import time
while True:
    mem = mx.metal.device_memory()
    print(f'GPU Memory: {mem}')
    time.sleep(5)
"
```

---

## Dataset Format

MLX expects JSONL format with each line being a valid JSON object.

### Supported Formats

**Instruction Format (Recommended)**
```json
{"text": "<|user|>\nWrite a SwiftUI view\n<|assistant|>\nimport SwiftUI\n\nstruct MyView: View {\n..."}
```

**Chat Format**
```json
{"text": "User: Ask\nAssistant: Answer"}
```

### Creating Your Dataset

Use the provided dataset generation scripts:

```bash
# From code examples
python3 generate_optimized_dataset.py

# Combined API + examples
python3 generate_unified_dataset.py
```

These create:
- `data/unified_train_dataset.jsonl` (80% training)
- `data/unified_test_dataset.jsonl` (20% validation)

---

## Usage from App

The app will integrate MLX support through:

1. **Configuration Option**: Select MLX as training method
2. **Memory Mode Selection**: Choose between standard/low/ultra-low memory
3. **Progress Monitoring**: Real-time training output

### For Now (Manual)

Until UI integration complete, run from terminal:

```bash
cd "/Users/mark/Documents/GitHub/AI Forge/Supporting Files/scripts"
python3 run_finetuning_mlx.py \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --low-memory \
  --epochs 1
```

---

## Common Issues & Solutions

### Issue: "mlx_lm module not found"
**Solution**: Run setup script or install:
```bash
pip3 install --upgrade mlx-lm
```

### Issue: "Model not found on HuggingFace"
**Solution**: Verify model name format:
```bash
# Check HuggingFace: https://huggingface.co/models
# Format: organization/model-name
python3 run_finetuning_mlx.py --model Qwen/Qwen2.5-Coder-7B-Instruct
```

### Issue: "GPU memory execution failed"
**Solution**: Use memory modes (in order):
```bash
# Try 1
--low-memory

# Try 2
--ultra-low-memory

# Try 3
--ultra-low-memory --learning-rate 1e-5
```

### Issue: "Dataset conversion error"
**Solution**: Verify dataset format:
```bash
# Check first line
head -1 data/unified_train_dataset.jsonl | python3 -m json.tool

# Count lines
wc -l data/unified_train_dataset.jsonl
```

### Issue: "Training is very slow"
**Solution**: Normal for M2. Consider:
- Reduce `--max-seq-length` to 128
- Reduce `--epochs` to 1
- Use smaller dataset subset
- Train on smaller model (3B instead of 7B)

---

## Performance Expectations

### M2 64GB RAM with 7B Model

| Mode | Batch Size | Seq Length | Time per Epoch | Notes |
|------|-----------|----------|-----------------|-------|
| Standard | 2 | 256 | 30-45 min | For ~3k examples |
| Low-Memory | 1 | 256 | 45-60 min | More stable |
| Ultra-Low | 1 | 128 | 20-30 min | Fastest, lower quality |

### Speed Optimization Tips

1. **Reduce sequence length**: 256 → 128 (2x faster)
2. **Reduce epochs**: 3 → 1 (3x faster)
3. **Smaller dataset**: Use first 1k examples for testing
4. **Smaller model**: 7B → 3B (much faster)

---

## Next Steps

### After Training Completes

1. **Adapters saved to**: `models/adapters/`

2. **Test the fine-tuned model**:
   ```bash
   python3 -c "
   from mlx_lm import conversational
   model, tokenizer = conversational.load_model('Qwen/Qwen2.5-Coder-7B-Instruct')
   # Load adapter and test
   "
   ```

3. **Evaluate quality**:
   - Test on example prompts
   - Check for overfitting with test set

4. **Optional: Convert to Ollama format**
   - Adapters can be merged and converted to Ollama
   - See: [MLX to Ollama Conversion Guide]

---

## Tips for Best Results

1. **Start Small**: Use 1 epoch first to verify setup
2. **Monitor Quality**: Check training/validation loss
3. **Adjust Hyperparameters**: If loss isn't decreasing
4. **Dataset Quality**: Clean, diverse examples work best
5. **Multiple Runs**: Fine-tune with different random seeds

---

## References

- [MLX Documentation](https://ml-explore.github.io/mlx/)
- [MLX-LM GitHub](https://github.com/ml-explore/mlx-lm)
- [LoRA Paper](https://arxiv.org/abs/2106.09685)
- [Qwen Model Card](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct)
