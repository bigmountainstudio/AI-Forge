#!/usr/bin/env python3
"""
Optimized Fine-Tuning Dataset Generator for SwiftUI

Processes .swift code example files from FineTuning/code_examples to create 
high-quality instruction-tuning data optimized for fine-tuning language models 
on SwiftUI development.
"""

import os
import re
import json
import random
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, field


@dataclass
class CodeExample:
    """Represents a parsed SwiftUI code example"""
    file_path: Path
    file_name: str
    topic: str
    subtopic: str
    category: str  # folder name (e.g., "SwiftUI Essentials")
    code: str
    imports: List[str] = field(default_factory=list)
    view_name: str = ""
    description: str = ""


class SwiftCodeExampleParser:
    """Parser optimized for SwiftUI code example files"""

    def __init__(self):
        # Patterns for extracting information
        self.import_pattern = re.compile(r'^import\s+(\w+)', re.MULTILINE)
        self.struct_pattern = re.compile(r'struct\s+(\w+)\s*:\s*View')
        self.header_desc_pattern = re.compile(
            r'HeaderView\([^)]*desc:\s*"([^"]+)"',
            re.DOTALL
        )
        self.comment_pattern = re.compile(r'//\s*NOTE:\s*(.+)$', re.MULTILINE)
        
        # Patterns for copyright/attribution comments to strip
        self.copyright_patterns = [
            re.compile(r'^\s*//\s*Created by.*$', re.MULTILINE),
            re.compile(r'^\s*//\s*Copyright.*$', re.MULTILINE),
            re.compile(r'^\s*//\s*@BigMtnStudio.*$', re.MULTILINE),
            re.compile(r'^\s*//\s*Twitter:.*$', re.MULTILINE),
            re.compile(r'^\s*//\s*All rights reserved.*$', re.MULTILINE),
        ]

    def parse_file(self, file_path: Path, category: str) -> Optional[CodeExample]:
        """Parse a Swift file into a CodeExample"""
        try:
            code = file_path.read_text(encoding='utf-8')
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return None

        if not code.strip():
            return None

        file_name = file_path.stem  # filename without extension
        topic, subtopic = self._parse_file_name(file_name)
        
        # Extract imports
        imports = self.import_pattern.findall(code)
        
        # Extract view name
        view_match = self.struct_pattern.search(code)
        view_name = view_match.group(1) if view_match else file_name
        
        # Extract description from HeaderView or comments (before stripping)
        description = self._extract_description(code)
        
        # Strip copyright comments for clean training data
        code = self._strip_copyright_comments(code)

        return CodeExample(
            file_path=file_path,
            file_name=file_name,
            topic=topic,
            subtopic=subtopic,
            category=category,
            code=code,
            imports=imports,
            view_name=view_name,
            description=description
        )

    def _parse_file_name(self, file_name: str) -> Tuple[str, str]:
        """Parse Topic_Subtopic from filename"""
        parts = file_name.split('_', 1)
        topic = parts[0]
        subtopic = parts[1] if len(parts) > 1 else "Introduction"
        
        # Convert camelCase/PascalCase to readable format
        topic = self._to_readable(topic)
        subtopic = self._to_readable(subtopic)
        
        return topic, subtopic

    def _to_readable(self, text: str) -> str:
        """Convert CamelCase to readable text"""
        # Insert space before capitals
        result = re.sub(r'([a-z])([A-Z])', r'\1 \2', text)
        # Handle consecutive capitals
        result = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', result)
        return result

    def _strip_copyright_comments(self, code: str) -> str:
        """Remove copyright and attribution comments from code"""
        for pattern in self.copyright_patterns:
            code = pattern.sub('', code)
        
        # Clean up multiple blank lines that may result from stripping
        code = re.sub(r'\n{3,}', '\n\n', code)
        
        # Remove leading blank lines
        code = code.lstrip('\n')
        
        return code

    def _extract_description(self, code: str) -> str:
        """Extract description from HeaderView or NOTE comments"""
        # Try HeaderView description first
        header_match = self.header_desc_pattern.search(code)
        if header_match:
            return header_match.group(1)
        
        # Try NOTE comments
        note_matches = self.comment_pattern.findall(code)
        if note_matches:
            return ' '.join(note_matches)
        
        return ""


class InstructionGenerator:
    """Generates diverse instruction-tuning examples from code examples"""

    def __init__(self):
        # Instruction templates for variety - optimized for accurate responses
        self.code_request_templates = [
            "Show me how to implement {topic} in SwiftUI.",
            "Write SwiftUI code that demonstrates {topic}.",
            "Give me an example of {topic} in SwiftUI.",
            "Create a SwiftUI view that shows {topic}.",
            "Demonstrate {topic} with SwiftUI code.",
        ]
        
        self.specific_code_templates = [
            "Show me how to {subtopic} with {topic} in SwiftUI.",
            "Write SwiftUI code for {topic} that demonstrates {subtopic}.",
            "Give me an example of {subtopic} with {topic} in SwiftUI.",
        ]
        
        self.question_templates = [
            "How do I use {topic} in SwiftUI?",
            "What's the best way to implement {topic} in SwiftUI?",
            "How do I {subtopic} using {topic} in SwiftUI?",
        ]

    def generate_examples(self, example: CodeExample) -> List[Dict[str, str]]:
        """Generate multiple instruction-tuning examples from a code example"""
        examples = []
        
        # Primary example: Direct code request with complete code response
        examples.append(self._generate_code_example(example))
        
        # Secondary example: Question format with explanation + code
        examples.append(self._generate_question_example(example))
        
        # Subtopic-specific example if subtopic is meaningful
        if example.subtopic.lower() not in ["intro", "introduction", "default"]:
            examples.append(self._generate_subtopic_example(example))
        
        # Framework-specific example for SwiftData/Charts
        if any(imp in example.imports for imp in ["SwiftData", "Charts"]):
            examples.append(self._generate_framework_example(example))

        return examples

    def _generate_code_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate a direct code request example - optimized for accuracy"""
        topic_display = f"{example.topic}"
        if example.subtopic.lower() not in ["intro", "introduction"]:
            topic_display = f"{example.topic} - {example.subtopic}"
        
        instruction = random.choice(self.code_request_templates).format(
            topic=topic_display.lower()
        )
        
        # Output is the complete, working code
        output = f"```swift\n{example.code.strip()}\n```"
        
        return {
            "instruction": instruction,
            "input": "",
            "output": output
        }

    def _generate_question_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate a question-style example with explanation + code"""
        instruction = self.question_templates[0].format(
            topic=example.topic.lower(),
            subtopic=example.subtopic.lower()
        )
        
        # Build response with optional description and complete code
        parts = []
        if example.description:
            parts.append(example.description)
            parts.append("")
        
        parts.append(f"Here's an example of {example.topic.lower()} in SwiftUI:")
        parts.append("")
        parts.append("```swift")
        parts.append(example.code.strip())
        parts.append("```")
        
        return {
            "instruction": instruction,
            "input": "",
            "output": "\n".join(parts)
        }

    def _generate_subtopic_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate a subtopic-specific example"""
        template = random.choice(self.specific_code_templates)
        instruction = template.format(
            topic=example.topic.lower(),
            subtopic=example.subtopic.lower()
        )
        
        output = f"```swift\n{example.code.strip()}\n```"
        
        return {
            "instruction": instruction,
            "input": "",
            "output": output
        }

    def _generate_framework_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate framework-specific example (SwiftData, Charts)"""
        frameworks = [imp for imp in example.imports if imp in ["SwiftData", "Charts"]]
        framework = frameworks[0] if frameworks else "SwiftUI"
        
        instruction = f"Show me how to use {framework} with {example.topic.lower()} in SwiftUI."
        
        parts = []
        parts.append(f"Here's an example using {framework} for {example.topic.lower()}:")
        parts.append("")
        parts.append("```swift")
        parts.append(example.code.strip())
        parts.append("```")
        
        return {
            "instruction": instruction,
            "input": "",
            "output": "\n".join(parts)
        }


def process_code_examples_directory(base_dir: Path) -> List[CodeExample]:
    """Process all Swift files in the code examples directory"""
    parser = SwiftCodeExampleParser()
    examples = []
    
    if not base_dir.exists():
        print(f"Directory not found: {base_dir}")
        return examples
    
    # Walk through all subdirectories
    for category_dir in base_dir.iterdir():
        if not category_dir.is_dir():
            continue
            
        category = category_dir.name
        print(f"Processing category: {category}")
        
        swift_files = list(category_dir.glob("*.swift"))
        print(f"  Found {len(swift_files)} Swift files")
        
        for swift_file in swift_files:
            example = parser.parse_file(swift_file, category)
            if example:
                examples.append(example)
    
    return examples


def generate_dataset(examples: List[CodeExample]) -> List[Dict[str, str]]:
    """Generate the full instruction-tuning dataset"""
    generator = InstructionGenerator()
    dataset = []
    
    for example in examples:
        instruction_examples = generator.generate_examples(example)
        dataset.extend(instruction_examples)
    
    return dataset


def save_dataset(dataset: List[Dict[str, str]], output_dir: Path, 
                 train_ratio: float = 0.8):
    """Save dataset to JSONL files with train/test split"""
    output_dir.mkdir(exist_ok=True)
    
    # Shuffle for randomization
    random.shuffle(dataset)
    
    # Save full dataset
    full_path = output_dir / "optimized_finetune_dataset.jsonl"
    with open(full_path, 'w', encoding='utf-8') as f:
        for example in dataset:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
    print(f"Saved full dataset: {full_path} ({len(dataset)} examples)")
    
    # Create train/test split
    split_idx = int(len(dataset) * train_ratio)
    train_data = dataset[:split_idx]
    test_data = dataset[split_idx:]
    
    train_path = output_dir / "optimized_train_dataset.jsonl"
    with open(train_path, 'w', encoding='utf-8') as f:
        for example in train_data:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
    print(f"Saved train dataset: {train_path} ({len(train_data)} examples)")
    
    test_path = output_dir / "optimized_test_dataset.jsonl"
    with open(test_path, 'w', encoding='utf-8') as f:
        for example in test_data:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
    print(f"Saved test dataset: {test_path} ({len(test_data)} examples)")


def main():
    """Main function to generate fine-tuning dataset from code examples"""
    
    # Paths - use current working directory (project directory)
    # The Swift app sets the working directory to the project path
    base_dir = Path.cwd()
    code_examples_dir = base_dir / "code_examples"
    output_dir = base_dir / "data"
    
    print("=" * 60)
    print("SwiftUI Fine-Tuning Dataset Generator")
    print("=" * 60)
    print(f"Code examples directory: {code_examples_dir}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Process all code examples
    print("Processing code examples...")
    examples = process_code_examples_directory(code_examples_dir)
    print(f"\nTotal code examples parsed: {len(examples)}")
    
    if not examples:
        print("No examples found. Exiting.")
        return
    
    # Generate instruction-tuning dataset
    print("\nGenerating instruction-tuning examples...")
    dataset = generate_dataset(examples)
    print(f"Total instruction-tuning examples generated: {len(dataset)}")
    
    # Save dataset
    print("\nSaving datasets...")
    save_dataset(dataset, output_dir)
    
    # Print summary statistics
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    
    # Count by category
    category_counts = {}
    for ex in examples:
        category_counts[ex.category] = category_counts.get(ex.category, 0) + 1
    
    print("\nExamples by category:")
    for category, count in sorted(category_counts.items()):
        print(f"  {category}: {count} files")
    
    print("\nDataset generation complete!")


if __name__ == "__main__":
    main()