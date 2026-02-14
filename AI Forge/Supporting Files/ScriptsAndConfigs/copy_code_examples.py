#!/usr/bin/env python3
"""
Copy Swift Code Examples to Fine Tuning Directory

This script copies Swift files from source directories into organized
directories for fine-tuning preparation.

Usage:
    python copy_code_examples.py
"""

import os
import shutil
from pathlib import Path

# Configuration: Source directories mapped to destination folders
SOURCE_MAPPING = {
    "Advanced SwiftUI Views Mastery": [
        "/Users/mark/Documents/GitHub/Advanced-SwiftUI-Views/Advanced-SwiftUI-Views/Advanced-SwiftUI-Views"
    ],
    "AI Mastery in SwiftUI": [
        "/Users/mark/Documents/GitHub/AI Mastery in SwiftUI",
        "/Users/mark/Documents/GitHub/AI Mastery in SwiftUI Bonus Projects"
    ],
    "SwiftData Mastery in SwiftUI": [
        "/Users/mark/Documents/GitHub/SwiftData_Mastery/SwiftData_Mastery",
        "/Users/mark/Documents/GitHub/SwiftData_Bonus_Projects"
    ],
    "SwiftUI Animations Mastery": [
        "/Users/mark/Documents/GitHub/SwiftUI-Animations/SwiftUIAnimations"
    ],
    "SwiftUI Charts Mastery": [
        "/Users/mark/Documents/GitHub/SwiftUI_Charts/SwiftUI_Charts"
    ],
    "SwiftUI Essentials": [
        "/Users/mark/Documents/GitHub/SwiftUI_Essentials/SwiftUI_Essentials"
    ],
    "SwiftUI Views Mastery": [
        "/Users/mark/Documents/GitHub/SwiftUI-Views/SwiftUI_Views"
    ]
}

# Base destination path for code examples
DEST_BASE = "/Users/mark/Documents/GitHub/Fine Tuning/FineTuning/code_examples"

def find_swift_files(source_dir: str) -> list[Path]:
    """Find all Swift files in a directory recursively."""
    source_path = Path(source_dir)
    if not source_path.exists():
        print(f"  ⚠️  Source directory not found: {source_dir}")
        return []
    
    swift_files = list(source_path.rglob("*.swift"))
    
    # Filter out common non-example files
    excluded_patterns = [
        'AppDelegate', 'SceneDelegate', 'ContentView.swift',
        'Assets.xcassets', '.build', 'Tests', 'UITests',
        'Package.swift', 'App.swift'
    ]
    
    filtered_files = []
    for f in swift_files:
        path_str = str(f)
        if not any(excl in path_str for excl in excluded_patterns):
            filtered_files.append(f)
    
    return filtered_files

def copy_files():
    """Copy all Swift files from source directories to destination."""
    
    total_copied = 0
    total_skipped = 0
    
    print("=" * 60)
    print("Copying Swift Code Examples for Fine Tuning")
    print("=" * 60)
    
    for dest_folder, source_dirs in SOURCE_MAPPING.items():
        print(f"\n📁 Processing: {dest_folder}")
        print("-" * 40)
        
        dest_path = Path(DEST_BASE) / dest_folder
        dest_path.mkdir(parents=True, exist_ok=True)
        
        folder_count = 0
        
        for source_dir in source_dirs:
            print(f"  📂 Source: {source_dir}")
            
            swift_files = find_swift_files(source_dir)
            print(f"     Found {len(swift_files)} Swift files")
            
            for swift_file in swift_files:
                try:
                    # Create destination filename
                    dest_file = dest_path / swift_file.name
                    
                    # Check if file already exists
                    if dest_file.exists():
                        print(f"     ⏭️  Skipped (exists): {swift_file.name}")
                        total_skipped += 1
                        continue
                    
                    # Copy the file
                    shutil.copy2(swift_file, dest_file)
                    print(f"     ✅ Copied: {swift_file.name}")
                    
                    folder_count += 1
                    total_copied += 1
                    
                except Exception as e:
                    print(f"     ❌ Error copying {swift_file.name}: {e}")
        
        print(f"  📊 Copied {folder_count} files for {dest_folder}")
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"✅ Copied:   {total_copied} files")
    print(f"⏭️  Skipped:  {total_skipped} files")
    print(f"📍 Output:   {DEST_BASE}")

if __name__ == "__main__":
    copy_files()