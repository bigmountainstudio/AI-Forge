#!/usr/bin/env python3
import os
import json
from pathlib import Path

kb_path = Path('RAG/swiftui_knowledge_base')
code_examples_path = Path('FineTuning/code_examples')
output_file = Path('FineTuning/swiftui_finetune_dataset.jsonl')

data = []
paths_to_walk = [kb_path, code_examples_path]
for path in paths_to_walk:
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(('.md', '.swift')):
                file_path = Path(root) / file
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read().strip()
                    if content:
                        # Simple text format for fine-tuning
                        data.append({
                            'text': f'Instruction: Answer SwiftUI questions based on documentation.\n\nDocumentation: {content[:2000]}\n\nResponse: Here is the SwiftUI information: {content[:1000]}'
                        })
                except Exception as e:
                    print(f'Error: {e}')

with open(output_file, 'w') as f:
    for item in data:
        f.write(json.dumps(item) + '\n')

print(f'Created dataset with {len(data)} examples')