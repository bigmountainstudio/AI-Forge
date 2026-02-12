#!/usr/bin/env python3
"""
Generate a unified fine-tuning dataset combining API definitions and code examples.

This script integrates:
1. API reference data from ../api_training_data/ (iOS 17+ only)
2. Practical code examples from code_examples/

The combined dataset provides both reference accuracy (API signatures/docs) and
practical patterns (working code in real contexts).

Outputs:
- data/unified_finetune_dataset.jsonl (full combined dataset)
- data/unified_train_dataset.jsonl (training data, 80%)
- data/unified_test_dataset.jsonl (test data, 20% for overfitting evaluation)
"""

import json
import random
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Optional, Tuple


MIN_IOS_VERSION: Tuple[int, int] = (17, 0)


@dataclass
class CodeExample:
    """Represents a parsed SwiftUI code example from code_examples/"""
    file_path: Path
    file_name: str
    topic: str
    subtopic: str
    category: str
    code: str
    imports: List[str] = field(default_factory=list)
    view_name: str = ""
    description: str = ""
    source_type: str = "code_example"


@dataclass
class ApiElement:
    """Represents a parsed API element from api_training_data/"""
    name: str
    kind: str
    signature: str
    doc: str
    ios_introduced: Optional[Tuple[int, int]]
    deprecated: bool
    unavailable: bool
    source_file: Path
    parent_type: Optional[str]
    source_type: str = "api_reference"

    @property
    def full_name(self) -> str:
        if self.parent_type and self.kind in {"func", "property"}:
            return f"{self.parent_type}.{self.name}"
        return self.name


# ============================================================================
# API PARSING (from generate_api_optimized_dataset.py)
# ============================================================================


def version_to_tuple(text: str) -> Tuple[int, int]:
    """Convert a version string like '17.2' into a tuple for comparison."""
    parts = text.strip().split(".")
    major = int(parts[0]) if parts else 0
    minor = int(parts[1]) if len(parts) > 1 else 0
    return major, minor


def is_version_at_least(version: Optional[Tuple[int, int]], target: Tuple[int, int]) -> bool:
    if version is None:
        return False
    return version >= target


def parse_ios_availability(avail_lines: List[str]) -> Tuple[Optional[Tuple[int, int]], bool, bool]:
    """Return (introduced_version, is_deprecated, is_unavailable) for iOS."""
    introduced: Optional[Tuple[int, int]] = None
    deprecated = False
    unavailable = False

    for raw in avail_lines:
        line = raw.strip()
        if "iOS" not in line:
            continue

        if "unavailable" in line:
            unavailable = True

        if "deprecated" in line or "obsoleted" in line:
            deprecated = True

        direct = re.search(r"iOS\s+([0-9]+(?:\.[0-9]+)?)", line)
        if direct:
            introduced = version_to_tuple(direct.group(1))
            continue

        introduced_match = re.search(r"introduced:\s*([0-9]+(?:\.[0-9]+)?)", line)
        if introduced_match:
            introduced = version_to_tuple(introduced_match.group(1))

    return introduced, deprecated, unavailable


def clean_doc_lines(doc_lines: List[str]) -> str:
    """Strip leading /// and collapse extra blank lines."""
    cleaned = []
    for line in doc_lines:
        content = line.lstrip("/").strip()
        cleaned.append(content)

    doc = "\n".join(cleaned).strip()
    doc = re.sub(r"\n{3,}", "\n\n", doc)
    return doc


def normalize_line(line: str) -> str:
    """Drop leading attributes and modifiers so regexes can match declarations."""
    stripped = line.strip()
    while stripped.startswith("@") and " " in stripped:
        stripped = stripped.split(" ", 1)[1].strip()

    leading_modifiers = {
        "nonisolated",
        "inlinable",
        "convenience",
        "mutating",
        "consuming",
        "borrowing",
        "isolated",
        "rethrows",
    }
    while True:
        parts = stripped.split(" ", 1)
        if parts and parts[0] in leading_modifiers:
            stripped = parts[1] if len(parts) > 1 else ""
            continue
        break
    return stripped


def extract_api_elements(swift_file: Path) -> List[ApiElement]:
    """Parse a Swift API definition file and extract eligible elements."""
    elements: List[ApiElement] = []
    text = swift_file.read_text(encoding="utf-8")
    lines = text.splitlines()

    doc_lines: List[str] = []
    avail_lines: List[str] = []
    type_stack: List[Tuple[str, int]] = []
    brace_depth = 0

    type_decl_re = re.compile(r"^(public|open|internal|fileprivate|private)?\s*(actor|class|struct|enum|protocol)\s+(\w+)")
    func_decl_re = re.compile(r"^(public|open|internal|fileprivate|private)?\s*(static\s+|class\s+)?func\s+(\w+)")
    init_decl_re = re.compile(r"^(public|open|internal|fileprivate|private)?\s*(static\s+|class\s+)?init\b")
    prop_decl_re = re.compile(r"^(public|open|internal|fileprivate|private)?\s*(static\s+|class\s+)?(var|let)\s+(\w+)")

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("///"):
            doc_lines.append(stripped)
            continue

        if stripped.startswith("@available"):
            avail_lines.append(stripped)
            continue

        normalized = normalize_line(stripped)

        type_match = type_decl_re.match(normalized)
        func_match = func_decl_re.match(normalized)
        prop_match = prop_decl_re.match(normalized)

        element_kind: Optional[str] = None
        element_name: Optional[str] = None

        if type_match:
            element_kind = type_match.group(2)
            element_name = type_match.group(3)
        elif func_match:
            element_kind = "func"
            element_name = func_match.group(3)
        elif init_decl_re.match(normalized):
            element_kind = "func"
            element_name = "init"
        elif prop_match:
            element_kind = "property"
            element_name = prop_match.group(4)

        if element_kind and element_name:
            parent_type = type_stack[-1][0] if type_stack else None
            introduced, deprecated, unavailable = parse_ios_availability(avail_lines)

            if is_version_at_least(introduced, MIN_IOS_VERSION) and not deprecated and not unavailable:
                doc = clean_doc_lines(doc_lines)
                signature_lines = [ln.strip() for ln in avail_lines] if avail_lines else []
                signature_lines.append(stripped)
                signature = "\n".join(signature_lines)

                elements.append(
                    ApiElement(
                        name=element_name,
                        kind=element_kind,
                        signature=signature,
                        doc=doc,
                        ios_introduced=introduced,
                        deprecated=deprecated,
                        unavailable=unavailable,
                        source_file=swift_file,
                        parent_type=parent_type,
                    )
                )

            doc_lines = []
            avail_lines = []

        open_braces = line.count("{")
        close_braces = line.count("}")
        brace_depth += open_braces - close_braces

        if type_match and open_braces > 0:
            type_stack.append((element_name, brace_depth))

        while type_stack and brace_depth < type_stack[-1][1]:
            type_stack.pop()

        if stripped.startswith("@") and not element_kind:
            continue

        if not element_kind and stripped and not stripped.startswith("//"):
            doc_lines = []
            avail_lines = []

    return elements


def load_all_api_elements(api_dir: Path) -> List[ApiElement]:
    """Load all API elements from .swift files in api_dir."""
    elements: List[ApiElement] = []
    for swift_file in sorted(api_dir.glob("*.swift")):
        print(f"  Scanning {swift_file.name}...")
        file_elements = extract_api_elements(swift_file)
        print(f"    Found {len(file_elements)} eligible symbols")
        elements.extend(file_elements)
    return elements


def format_availability(element: ApiElement) -> str:
    """Format version tuple as readable string."""
    version = element.ios_introduced
    if not version:
        return "iOS 17+"
    major, minor = version
    return f"iOS {major}.{minor}+"


def build_api_output(element: ApiElement) -> str:
    """Build the output text for an API element."""
    parts = []
    if element.doc:
        parts.append(element.doc)
        parts.append("")

    parts.append("Declaration:")
    parts.append("```swift")
    parts.append(element.signature.strip())
    parts.append("```")
    parts.append("")

    parts.append(f"Availability: {format_availability(element)}")
    if element.parent_type:
        parts.append(f"Member of: {element.parent_type}")
    parts.append(f"Source: {element.source_file.name}")

    return "\n".join(parts).strip()


def build_api_examples(element: ApiElement) -> List[dict]:
    """Generate instruction examples from an API element."""
    output = build_api_output(element)
    base = element.full_name
    avail = format_availability(element)

    templates: List[str] = []
    if element.kind in {"class", "struct", "enum", "actor", "protocol"}:
        templates = [
            f"Explain the {element.kind} {base} for {avail}.",
            f"Show the Swift declaration and summary for {base} on {avail}.",
        ]
    elif element.kind == "func":
        templates = [
            f"How do I use {base}() on {avail}?",
            f"Describe the purpose of {base} and show its declaration for {avail}.",
        ]
    else:  # property
        templates = [
            f"What does {base} provide on {avail}?",
            f"Document the property {base} for {avail}.",
        ]

    return [
        {"instruction": template, "input": "", "output": output}
        for template in templates
    ]


# ============================================================================
# CODE EXAMPLE PARSING (from generate_optimized_dataset.py)
# ============================================================================


class SwiftCodeExampleParser:
    """Parser for SwiftUI code example files."""

    def __init__(self):
        self.import_pattern = re.compile(r"^import\s+(\w+)", re.MULTILINE)
        self.struct_pattern = re.compile(r"struct\s+(\w+)\s*:\s*View")
        self.header_desc_pattern = re.compile(
            r'HeaderView\([^)]*desc:\s*"([^"]+)"',
            re.DOTALL
        )
        self.comment_pattern = re.compile(r"//\s*NOTE:\s*(.+)$", re.MULTILINE)
        
        self.copyright_patterns = [
            re.compile(r"^\s*//\s*Created by.*$", re.MULTILINE),
            re.compile(r"^\s*//\s*Copyright.*$", re.MULTILINE),
            re.compile(r"^\s*//\s*@BigMtnStudio.*$", re.MULTILINE),
            re.compile(r"^\s*//\s*Twitter:.*$", re.MULTILINE),
            re.compile(r"^\s*//\s*All rights reserved.*$", re.MULTILINE),
        ]

    def parse_file(self, file_path: Path, category: str) -> Optional[CodeExample]:
        """Parse a Swift file into a CodeExample."""
        try:
            code = file_path.read_text(encoding="utf-8")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return None

        if not code.strip():
            return None

        file_name = file_path.stem
        topic, subtopic = self._parse_file_name(file_name)
        
        imports = self.import_pattern.findall(code)
        view_match = self.struct_pattern.search(code)
        view_name = view_match.group(1) if view_match else file_name
        
        description = self._extract_description(code)
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
        """Parse Topic_Subtopic from filename."""
        parts = file_name.split("_", 1)
        topic = parts[0]
        subtopic = parts[1] if len(parts) > 1 else "Introduction"
        
        topic = self._to_readable(topic)
        subtopic = self._to_readable(subtopic)
        
        return topic, subtopic

    def _to_readable(self, text: str) -> str:
        """Convert CamelCase to readable text."""
        result = re.sub(r"([a-z])([A-Z])", r"\1 \2", text)
        result = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", result)
        return result

    def _strip_copyright_comments(self, code: str) -> str:
        """Remove copyright and attribution comments."""
        for pattern in self.copyright_patterns:
            code = pattern.sub("", code)
        
        code = re.sub(r"\n{3,}", "\n\n", code)
        code = code.lstrip("\n")
        
        return code

    def _extract_description(self, code: str) -> str:
        """Extract description from HeaderView or NOTE comments."""
        header_match = self.header_desc_pattern.search(code)
        if header_match:
            return header_match.group(1)
        
        note_matches = self.comment_pattern.findall(code)
        if note_matches:
            return " ".join(note_matches)
        
        return ""


class InstructionGenerator:
    """Generates instruction examples from code examples."""

    def __init__(self):
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
        """Generate instruction examples from a code example."""
        examples = []
        
        examples.append(self._generate_code_example(example))
        examples.append(self._generate_question_example(example))
        
        if example.subtopic.lower() not in ["intro", "introduction", "default"]:
            examples.append(self._generate_subtopic_example(example))
        
        if any(imp in example.imports for imp in ["SwiftData", "Charts"]):
            examples.append(self._generate_framework_example(example))

        return examples

    def _generate_code_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate a direct code request example."""
        topic_display = f"{example.topic}"
        if example.subtopic.lower() not in ["intro", "introduction"]:
            topic_display = f"{example.topic} - {example.subtopic}"
        
        instruction = random.choice(self.code_request_templates).format(
            topic=topic_display.lower()
        )
        
        output = f"```swift\n{example.code.strip()}\n```"
        
        return {
            "instruction": instruction,
            "input": "",
            "output": output
        }

    def _generate_question_example(self, example: CodeExample) -> Dict[str, str]:
        """Generate a question-style example."""
        instruction = self.question_templates[0].format(
            topic=example.topic.lower(),
            subtopic=example.subtopic.lower()
        )
        
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
        """Generate a subtopic-specific example."""
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
        """Generate framework-specific example."""
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
    """Process all Swift files in code examples directory."""
    parser = SwiftCodeExampleParser()
    examples = []
    
    if not base_dir.exists():
        print(f"Directory not found: {base_dir}")
        return examples
    
    for category_dir in base_dir.iterdir():
        if not category_dir.is_dir():
            continue
            
        category = category_dir.name
        print(f"  Scanning category: {category}")
        
        swift_files = list(category_dir.glob("*.swift"))
        print(f"    Found {len(swift_files)} Swift files")
        
        for swift_file in swift_files:
            example = parser.parse_file(swift_file, category)
            if example:
                examples.append(example)
    
    return examples


def generate_code_dataset(examples: List[CodeExample]) -> List[Dict[str, str]]:
    """Generate instruction-tuning dataset from code examples."""
    generator = InstructionGenerator()
    dataset = []
    
    for example in examples:
        instruction_examples = generator.generate_examples(example)
        dataset.extend(instruction_examples)
    
    return dataset


def save_unified_datasets(dataset: List[Dict[str, str]], output_dir: Path, 
                         train_ratio: float = 0.8) -> None:
    """Save unified dataset with train/test split."""
    output_dir.mkdir(parents=True, exist_ok=True)
    random.shuffle(dataset)

    full_path = output_dir / "unified_finetune_dataset.jsonl"
    with full_path.open("w", encoding="utf-8") as f:
        for row in dataset:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    split = int(len(dataset) * train_ratio)
    train_rows = dataset[:split]
    test_rows = dataset[split:]

    train_path = output_dir / "unified_train_dataset.jsonl"
    test_path = output_dir / "unified_test_dataset.jsonl"

    with train_path.open("w", encoding="utf-8") as f:
        for row in train_rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    with test_path.open("w", encoding="utf-8") as f:
        for row in test_rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"Saved full unified dataset to {full_path} ({len(dataset)} rows)")
    print(f"Saved train split to {train_path} ({len(train_rows)} rows)")
    print(f"Saved test split to {test_path} ({len(test_rows)} rows)")


def main() -> None:
    """Generate unified dataset from API definitions and code examples."""
    
    script_dir = Path(__file__).parent
    base_dir = script_dir.parent
    api_dir = base_dir.parent / "api_training_data"
    code_examples_dir = base_dir / "code_examples"
    output_dir = base_dir / "data"

    print("=" * 70)
    print("Generating UNIFIED fine-tuning dataset")
    print("=" * 70)
    print(f"API directory: {api_dir}")
    print(f"Code examples directory: {code_examples_dir}")
    print(f"Output directory: {output_dir}\n")

    # Load API elements
    print("Loading API definitions...")
    if not api_dir.exists():
        print(f"API directory not found: {api_dir}")
        return
    
    api_elements = load_all_api_elements(api_dir)
    print(f"Total eligible API elements: {len(api_elements)}\n")

    # Generate API examples
    print("Generating instruction examples from API definitions...")
    api_examples: List[Dict[str, str]] = []
    for element in api_elements:
        api_examples.extend(build_api_examples(element))
    print(f"Total API instruction pairs: {len(api_examples)}\n")

    # Load code examples
    print("Loading code examples...")
    if not code_examples_dir.exists():
        print(f"Code examples directory not found: {code_examples_dir}")
        code_examples = []
    else:
        code_examples = process_code_examples_directory(code_examples_dir)
        print(f"Total code examples parsed: {len(code_examples)}\n")

    # Generate code examples
    print("Generating instruction examples from code examples...")
    code_instruction_examples = generate_code_dataset(code_examples)
    print(f"Total code instruction pairs: {len(code_instruction_examples)}\n")

    # Combine datasets
    unified_dataset = api_examples + code_instruction_examples
    print(f"TOTAL unified dataset size: {len(unified_dataset)} instruction pairs")
    
    # Save unified datasets
    print("\nSaving unified datasets...")
    save_unified_datasets(unified_dataset, output_dir)

    # Print summary
    print("\n" + "=" * 70)
    print("Summary")
    print("=" * 70)
    print(f"API reference pairs: {len(api_examples)}")
    print(f"Code example pairs: {len(code_instruction_examples)}")
    print(f"Total combined pairs: {len(unified_dataset)}")
    print(f"\nBreakdown by framework (code examples):")
    
    category_counts = {}
    for ex in code_examples:
        category_counts[ex.category] = category_counts.get(ex.category, 0) + 1
    
    for category, count in sorted(category_counts.items()):
        print(f"  {category}: {count} files")
    
    print("\nUnified dataset generation complete!")
    print("Ready for fine-tuning in Step 3 of Fine Tuning Guide.")


if __name__ == "__main__":
    main()
