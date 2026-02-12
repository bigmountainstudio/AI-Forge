# Fine Tuning Guide
LoRA (Low-Rank Adaptation) for Parameter Efficient Fine Tuning

## Overview
This guide provides a comprehensive, automated workflow for fine-tuning language models on SwiftUI knowledge using source API files and code examples. The process extracts structured instruction-tuning data directly from Swift interface files and example code for optimal model performance.

## Prerequisites
- Python 3.8+
- Access to SwiftUI source API files (.swift interface files)
- Fine-tuning framework (Axolotl, Unsloth, or similar)
- Base model (qwen2.5-coder:7b recommended)

## Step-by-Step Workflow

## Step 1: Prepare Source Files
Place your SwiftUI source files in the appropriate directories:

### API Documentation Files
- **Location**: `../api_training_data/`
- **Type**: Raw Swift interface files (.swift)
- **Content**: API definitions with documentation comments
- **Example**: `SwiftUI Framework API.swift`, `Charts Framework API.swift`

### Code Example Files
- **Location**: `code_examples/`
- **Type**: Raw Swift files (.swift)
- **Content**: Complete, working SwiftUI examples
- **Example**: Animation examples, data management patterns, UI components

The script automatically processes both types of source files to create comprehensive training data.

### Step 2: Generate Optimized Dataset
#### Step 2.1: Instruction Generation from Code Examples
Run the automated dataset generation script for code examples:

```bash
cd FineTuning
python3 scripts/generate_optimized_dataset.py
```
This script will:
- Scan all Swift files in `code_examples/` subfolders and parse topics, subtopics, imports, view names, and optional descriptions from `HeaderView`/`NOTE` comments.
- Strip attribution/copyright comments and normalize whitespace to keep the training code clean.
- Generate multiple instruction-tuning variants per example (direct code requests, question-style explanations, subtopic prompts, and framework-specific prompts for SwiftData/Charts).
- Shuffle and write the full dataset to `data/optimized_finetune_dataset.jsonl`.
- Create an 80/20 train/test split and save to `data/optimized_train_dataset.jsonl` and `data/optimized_test_dataset.jsonl`.
- Print per-category file counts and a completion summary.


#### Step 2.2: Generate Unified Dataset (API + Code Examples)
Run the unified dataset generation script that combines both API reference data and practical code examples:

```bash
cd FineTuning
python3 scripts/generate_unified_dataset.py
```

This script will:
- Parse all .swift files in `../api_training_data/` for API reference data
- Extract API elements (classes, structs, functions, properties) for only iOS 17+ APIs
- Exclude deprecated APIs and those not available in iOS 17
- Parse all code examples from `code_examples/` subdirectories
- Generate instruction-tuning examples from both sources in optimized format
- Combine both datasets (API reference + practical code patterns)
- Create balanced train/test splits (80/20) for evaluation
- Output files:
  - `data/unified_finetune_dataset.jsonl` (full combined dataset)
  - `data/unified_train_dataset.jsonl` (training data, 80%)
  - `data/unified_test_dataset.jsonl` (test data, 20% for overfitting evaluation)

**Note**: The unified dataset combines:
- **API Reference Examples**: Swift declarations, documentation, and availability info (for accuracy)
- **Code Examples**: Real working SwiftUI implementations (for practical patterns)

### Step 3: Configure Fine-Tuning
Update the Axolotl configuration file (`config/axolotl_config.yaml`):

```yaml
base_model: qwen2.5-coder:7b
model_type: LlamaForCausalLM
tokenizer_type: LlamaTokenizer

datasets:
  - path: data/unified_train_dataset.jsonl
    type: jsonl
    field_instruction: instruction
    field_input: input
    field_output: output

output_dir: ./swiftui-finetuned-model
```

### Step 4: Run Fine-Tuning
Execute the fine-tuning process:

```bash
# Using Axolotl
axolotl train config/axolotl_config.yaml

# Or using Unsloth
# Follow Unsloth documentation for instruction tuning
```

### Step 5: Evaluate for Overfitting
Test the fine-tuned model on held-out test data:

```bash
# Test on training data (should perform well)
ollama run swiftui-expert-$(date +%Y%m%d%H) "<sample from data/unified_train_dataset.jsonl>"

# Test on test data (should perform similarly if not overfitting)
ollama run swiftui-expert-$(date +%Y%m%d%H) "<sample from data/unified_test_dataset.jsonl>"

# Compare performance - if test accuracy << train accuracy, reduce training or add regularization
```

### Step 6: Convert and Deploy
Convert the fine-tuned model for inference:

```bash
# Convert to Ollama format (using dynamic versioned naming: YYYYMMDDHH)
ollama create swiftui-expert-$(date +%Y%m%d%H) -f Modelfile

# Modelfile content:
FROM ./swiftui-finetuned-model
SYSTEM """
You are a SwiftUI expert with deep knowledge of modern iOS development.
Always use the latest APIs and provide accurate, helpful code examples.
"""
PARAMETER num_ctx 32768
```

## Dataset Format
The optimized dataset uses the standard instruction-tuning format with examples from both API documentation and code examples:

### API Documentation Examples
```json
{
  "instruction": "Explain how to use the Button struct in SwiftUI.",
  "input": "API: struct Button\nDescription: A control that initiates an action.\nAvailable in iOS 13.0+",
  "output": "The Button struct creates interactive controls in SwiftUI... [detailed API explanation]"
}
```

### Code Example Explanations
```json
{
  "instruction": "How do I implement custom animations in SwiftUI?",
  "input": "Description: Demonstrates SwiftUI animation patterns\n\nCode example file: Example_WithAnimation.md",
  "output": "To implement custom animations in SwiftUI, follow this pattern:\n\n```swift\n[Swift code example]...\n```\n\nThis example demonstrates..."
}
```

## Quality Improvements Over Previous Approach
- **Structured Parsing**: Direct extraction from source .swift files instead of processed MD files
- **Instruction Format**: Proper instruction-input-output structure optimized for fine-tuning
- **Context Preservation**: Maintains API signatures and iOS version requirements
- **Scalability**: Automated processing of any number of source files
- **Evaluation Ready**: Built-in train/test splits for overfitting detection

## Troubleshooting
- **No API files found**: Ensure .swift files are in `../api_training_data/` folder
- **Parsing errors**: Check that source files are valid Swift interface files
- **Overfitting**: Reduce learning rate, add dropout, or increase dataset size
- **Poor performance**: Verify base model compatibility and dataset quality

## Future Enhancements
- ✅ **Code example integration**: Implemented - now processes both API docs and code examples
- Implement quality filtering for generated examples
- Add multi-turn conversation format support
- Integrate automated evaluation metrics

## The guide Gemini made
https://docs.google.com/document/d/1KiG1aW1_vhC3fomxOZLi0aNSkhsmq4Jj7GIpxMGlvds/edit?tab=t.0

