#!/usr/bin/env python3
"""
Generate instruction-tuning data from Apple API definition .swift files.

Steps performed:
- Parse all .swift files in ../api_training_data
- Keep only APIs that are available on iOS 17 or later
- Drop deprecated or unavailable APIs
- Extract doc comments plus the declaration signature for types/members
- Emit instruction/output pairs in the optimized JSONL format
- Create an 80/20 train/test split for overfitting evaluation

Outputs (written to FineTuning/data):
- optimized_finetune_dataset.jsonl
- optimized_train_dataset.jsonl
- optimized_test_dataset.jsonl
"""

import json
import random
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


MIN_IOS_VERSION: Tuple[int, int] = (17, 0)


@dataclass
class ApiElement:
    """A single API surface element captured from the doc sources."""

    name: str
    kind: str  # class | struct | enum | actor | protocol | func | property
    signature: str
    doc: str
    ios_introduced: Optional[Tuple[int, int]]
    deprecated: bool
    unavailable: bool
    source_file: Path
    parent_type: Optional[str]

    @property
    def full_name(self) -> str:
        if self.parent_type and self.kind in {"func", "property"}:
            return f"{self.parent_type}.{self.name}"
        return self.name


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

        # Pattern 1: @available(iOS 17.0, macOS 14.0, *)
        direct = re.search(r"iOS\s+([0-9]+(?:\.[0-9]+)?)", line)
        if direct:
            introduced = version_to_tuple(direct.group(1))
            continue

        # Pattern 2: @available(iOS, introduced: 17.0, deprecated: 18.0)
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
    """Drop leading attributes so regexes can match declarations."""

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
    elements: List[ApiElement] = []
    text = swift_file.read_text(encoding="utf-8")
    lines = text.splitlines()

    doc_lines: List[str] = []
    avail_lines: List[str] = []
    type_stack: List[Tuple[str, int]] = []  # (type_name, depth)
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

        # Update brace tracking after processing the declaration
        open_braces = line.count("{")
        close_braces = line.count("}")
        brace_depth += open_braces - close_braces

        # Push new type context when we see a type declaration with an opening brace
        if type_match and open_braces > 0:
            type_stack.append((element_name, brace_depth))

        # Pop types when we exit their brace scope
        while type_stack and brace_depth < type_stack[-1][1]:
            type_stack.pop()

        # Attribute-only lines should not wipe doc context
        if stripped.startswith("@") and not element_kind:
            continue

        # If we encounter unrelated code, clear stray docs/availability
        if not element_kind and stripped and not stripped.startswith("//"):
            doc_lines = []
            avail_lines = []

    return elements


def load_all_api_elements(api_dir: Path) -> List[ApiElement]:
    elements: List[ApiElement] = []
    for swift_file in sorted(api_dir.glob("*.swift")):
        print(f"Scanning {swift_file.name}...")
        file_elements = extract_api_elements(swift_file)
        print(f"  found {len(file_elements)} eligible symbols")
        elements.extend(file_elements)
    return elements


def format_availability(element: ApiElement) -> str:
    version = element.ios_introduced
    if not version:
        return "iOS 17+"
    major, minor = version
    return f"iOS {major}.{minor}+"


def build_output_text(element: ApiElement) -> str:
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


def build_instruction_examples(element: ApiElement) -> List[dict]:
    output = build_output_text(element)
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


def save_datasets(dataset: List[dict], output_dir: Path, train_ratio: float = 0.8) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    random.shuffle(dataset)

    full_path = output_dir / "optimized_finetune_dataset.jsonl"
    with full_path.open("w", encoding="utf-8") as f:
        for row in dataset:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    split = int(len(dataset) * train_ratio)
    train_rows = dataset[:split]
    test_rows = dataset[split:]

    train_path = output_dir / "optimized_train_dataset.jsonl"
    test_path = output_dir / "optimized_test_dataset.jsonl"

    with train_path.open("w", encoding="utf-8") as f:
        for row in train_rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    with test_path.open("w", encoding="utf-8") as f:
        for row in test_rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"Saved full dataset to {full_path} ({len(dataset)} rows)")
    print(f"Saved train split to {train_path} ({len(train_rows)} rows)")
    print(f"Saved test split to {test_path} ({len(test_rows)} rows)")


def main() -> None:
    # Use current working directory as base (project directory)
    # The Swift app sets the working directory to the project path
    base_dir = Path.cwd()
    api_dir = base_dir.parent / "api_training_data"
    output_dir = base_dir / "data"

    print("=" * 60)
    print("Generating optimized dataset from API definitions")
    print("=" * 60)
    print(f"API directory: {api_dir}")
    print(f"Output directory: {output_dir}\n")

    if not api_dir.exists():
        print(f"API directory not found: {api_dir}")
        return

    elements = load_all_api_elements(api_dir)
    print(f"Total eligible API elements: {len(elements)}")

    dataset: List[dict] = []
    for element in elements:
        dataset.extend(build_instruction_examples(element))

    print(f"Total instruction-output pairs: {len(dataset)}")
    save_datasets(dataset, output_dir)


if __name__ == "__main__":
    main()