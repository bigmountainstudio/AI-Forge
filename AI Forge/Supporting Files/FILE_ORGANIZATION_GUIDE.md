# File Organization Guide for Python Script Integration

## Overview

This document describes how the AI Forge application organizes source files to ensure compatibility with Python dataset generation scripts. The file organization is critical for the `generate_optimized_dataset.py` and `generate_unified_dataset.py` scripts to correctly locate and process files.

## Directory Structure

The file organization follows this structure relative to the project root:

```
AIForge/
├── Supporting Files/
│   ├── scripts/
│   │   ├── generate_optimized_dataset.py
│   │   ├── generate_unified_dataset.py
│   │   └── ... (other scripts)
│   └── Fine Tuning Guide.md
├── FineTuning/
│   ├── code_examples/          ← Code example files (relative to scripts/)
│   │   ├── SwiftUI Essentials/
│   │   │   ├── Animation_Basic.swift
│   │   │   ├── State_Management.swift
│   │   │   └── ...
│   │   ├── Data Management/
│   │   │   ├── SwiftData_Basics.swift
│   │   │   └── ...
│   │   └── ...
│   ├── api_training_data/      ← API documentation files (one level up from scripts/)
│   │   ├── SwiftUI_Framework_API.swift
│   │   ├── Charts_Framework_API.swift
│   │   └── ...
│   └── data/                   ← Generated datasets (output)
│       ├── optimized_finetune_dataset.jsonl
│       ├── optimized_train_dataset.jsonl
│       ├── optimized_test_dataset.jsonl
│       ├── unified_finetune_dataset.jsonl
│       ├── unified_train_dataset.jsonl
│       └── unified_test_dataset.jsonl
└── api_training_data/          ← Alternative location (one level up from FineTuning/)
    ├── SwiftUI_Framework_API.swift
    └── ...
```

## File Organization by Category

### API Documentation Files

**Location**: `../api_training_data/` (relative to the scripts directory)

**Purpose**: Raw Swift interface files containing API definitions with documentation comments

**File Format**: `.swift` files

**Content Requirements**:
- Swift interface definitions (classes, structs, enums, protocols)
- Documentation comments (///)
- Availability annotations (@available)
- iOS 17+ APIs only (older APIs are filtered out)

**Example Files**:
- `SwiftUI_Framework_API.swift` - SwiftUI framework API definitions
- `Charts_Framework_API.swift` - Charts framework API definitions
- `SwiftData_Framework_API.swift` - SwiftData framework API definitions

**Python Script Usage**:
- `generate_unified_dataset.py` reads from `../api_training_data/`
- Extracts API elements (classes, structs, functions, properties)
- Filters for iOS 17+ availability
- Excludes deprecated and unavailable APIs
- Generates instruction-tuning examples with API signatures and documentation

### Code Example Files

**Location**: `code_examples/` (relative to the scripts directory)

**Purpose**: Complete, working SwiftUI examples demonstrating practical patterns

**File Format**: `.swift` files organized in category subdirectories

**Directory Structure**:
```
code_examples/
├── SwiftUI Essentials/
│   ├── Animation_Basic.swift
│   ├── State_Management.swift
│   └── ...
├── Data Management/
│   ├── SwiftData_Basics.swift
│   ├── Core Data_Integration.swift
│   └── ...
├── UI Components/
│   ├── Custom_Views.swift
│   └── ...
└── ...
```

**Content Requirements**:
- Complete, working SwiftUI code
- Proper imports (import SwiftUI, etc.)
- View structs that conform to View protocol
- Optional: HeaderView with description or NOTE comments
- Copyright/attribution comments are stripped during processing

**File Naming Convention**:
- Format: `Topic_Subtopic.swift`
- Examples: `Animation_Basic.swift`, `State_Management.swift`
- Converted to readable format: "Animation Basic", "State Management"

**Python Script Usage**:
- `generate_optimized_dataset.py` reads from `code_examples/` subdirectories
- Recursively scans all `.swift` files
- Parses file names to extract topics and subtopics
- Extracts imports, view names, and descriptions
- Strips copyright comments for clean training data
- Generates multiple instruction-tuning variants per example

## File Organization in AI Forge Application

### During File Selection

When users add files through the SourceFilesView:

1. **API Documentation Selection**:
   - User clicks "Add API Docs" button
   - File picker opens in folder/file selection mode
   - User selects individual files or entire folders
   - Files are copied to `../api_training_data/`

2. **Code Examples Selection**:
   - User clicks "Add Examples" button
   - File picker opens in folder/file selection mode
   - User selects individual files or entire folders
   - Files are copied to `code_examples/`

### File Organization Implementation

The `FileSystemManager` class handles file organization:

```swift
// API Documentation files
destinationDir = projectURL.deletingLastPathComponent()
                           .appendingPathComponent("api_training_data", isDirectory: true)

// Code Example files
destinationDir = projectURL.appendingPathComponent("code_examples", isDirectory: true)
```

### Folder Scanning

When users select a folder, the `findSwiftFiles(in:)` method:
- Recursively scans the folder and all subdirectories
- Discovers all `.swift` files
- Returns URLs for all discovered files
- Skips hidden files and non-Swift files

## Python Script Expectations

### generate_optimized_dataset.py

**Input**:
- Reads from: `code_examples/` subdirectories
- File type: `.swift` files
- Recursively scans all subdirectories

**Processing**:
1. Enumerates all category subdirectories
2. For each category, finds all `.swift` files
3. Parses file names to extract topics and subtopics
4. Extracts imports, view names, and descriptions
5. Strips copyright comments
6. Generates instruction-tuning examples

**Output**:
- `data/optimized_finetune_dataset.jsonl` - Full dataset
- `data/optimized_train_dataset.jsonl` - Training split (80%)
- `data/optimized_test_dataset.jsonl` - Test split (20%)

**Key Code**:
```python
code_examples_dir = base_dir / "code_examples"
for category_dir in base_dir.iterdir():
    if not category_dir.is_dir():
        continue
    swift_files = list(category_dir.glob("*.swift"))
```

### generate_unified_dataset.py

**Input**:
- API files from: `../api_training_data/` (one level up from scripts)
- Code examples from: `code_examples/` subdirectories
- File type: `.swift` files

**Processing**:
1. Loads all API elements from `../api_training_data/`
2. Filters for iOS 17+ availability
3. Loads all code examples from `code_examples/`
4. Generates instruction-tuning examples from both sources
5. Combines datasets

**Output**:
- `data/unified_finetune_dataset.jsonl` - Full combined dataset
- `data/unified_train_dataset.jsonl` - Training split (80%)
- `data/unified_test_dataset.jsonl` - Test split (20%)

**Key Code**:
```python
api_dir = base_dir.parent / "api_training_data"
code_examples_dir = base_dir / "code_examples"
```

## Verification Checklist

### API Documentation Files

- [ ] Files are located in `../api_training_data/` relative to the project
- [ ] All files have `.swift` extension
- [ ] Files contain Swift interface definitions
- [ ] Files include documentation comments (///)
- [ ] Files include availability annotations (@available)
- [ ] Only iOS 17+ APIs are included
- [ ] Deprecated APIs are excluded
- [ ] `generate_unified_dataset.py` can locate and parse files
- [ ] Generated API instruction examples are correct

### Code Example Files

- [ ] Files are located in `code_examples/` subdirectories
- [ ] All files have `.swift` extension
- [ ] Files are organized in category subdirectories
- [ ] File names follow `Topic_Subtopic.swift` convention
- [ ] Files contain complete, working SwiftUI code
- [ ] Files include proper imports
- [ ] Files include View structs
- [ ] Optional: Files include HeaderView descriptions or NOTE comments
- [ ] `generate_optimized_dataset.py` can locate and parse files
- [ ] `generate_unified_dataset.py` can locate and parse files
- [ ] Generated instruction examples are correct
- [ ] Recursive folder scanning discovers all files

### Integration

- [ ] AI Forge SourceFilesView correctly organizes files
- [ ] FileSystemManager places API docs in `../api_training_data/`
- [ ] FileSystemManager places code examples in `code_examples/`
- [ ] FileSystemManager recursively scans folders
- [ ] File removal only deletes individual files, not entire folders
- [ ] File persistence works across step navigation
- [ ] Python scripts can locate all organized files
- [ ] Dataset generation completes without errors
- [ ] Generated datasets contain expected number of examples

## Troubleshooting

### Python Script Cannot Find Files

**Issue**: `generate_optimized_dataset.py` or `generate_unified_dataset.py` reports "Directory not found"

**Solution**:
1. Verify the script is run from the correct directory (FineTuning/)
2. Check that `code_examples/` exists and contains subdirectories
3. Check that `../api_training_data/` exists (for unified dataset)
4. Verify file permissions allow reading

### No Swift Files Found

**Issue**: Python script finds directory but reports "No .swift files found"

**Solution**:
1. Verify files have `.swift` extension (not `.txt`, `.md`, etc.)
2. Check that files are in the correct subdirectories
3. Verify files are not hidden (don't start with `.`)
4. Check file permissions

### Incorrect File Organization

**Issue**: Files are in wrong directories or not organized by category

**Solution**:
1. Verify AI Forge is using correct category when adding files
2. Check FileSystemManager implementation for correct paths
3. Verify file picker is selecting correct category
4. Check that folder scanning is working correctly

## Related Documentation

- [Fine Tuning Guide](./Fine%20Tuning%20Guide.md) - Complete fine-tuning workflow
- [SourceFileReference Model](../Shared/Models/SourceFileReference.swift) - File reference data structure
- [FileSystemManager Service](../Shared/Services/FileSystemManager.swift) - File organization implementation
- [SourceFilesView](../Views/Workflow/SourceFilesView.swift) - User interface for file selection

