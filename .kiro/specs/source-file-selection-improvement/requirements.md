# Requirements Document: Source File Selection Improvement

## Introduction

The Source File Selection Improvement feature enhances the AI Forge application's ability to distinguish between two types of source files during the file selection process: API Documentation Files and Code Example Files. Currently, the SourceFilesView allows users to add files but does not guide them to select different file types for different purposes. This improvement separates the selection workflow so that each file type is properly categorized and placed in the correct directory structure, ensuring the Python scripts (generate_optimized_dataset.py and generate_unified_dataset.py) receive correctly organized input data.

## Glossary

- **API_Documentation_Files**: Raw Swift interface files (.swift) containing API definitions with documentation comments, located in `../api_training_data/`
- **Code_Example_Files**: Raw Swift files (.swift) containing complete, working SwiftUI examples, located in `code_examples/`
- **Source_File_Category**: An enumeration that distinguishes between API documentation and code examples
- **File_Picker**: The macOS file selection dialog that allows users to select files from the filesystem
- **Category_Selection**: The UI mechanism that guides users to select files for a specific category
- **File_Validation**: The process of verifying that selected files are appropriate for their assigned category
- **Directory_Structure**: The organized folder layout where API documentation and code examples are stored separately
- **SourceFilesView**: The SwiftUI view component that manages file selection and display
- **StepDetailObservable**: The view model that coordinates file operations and state management
- **FileSystemManager**: The service that handles file operations and directory management

## Requirements

### Requirement 1: Separate File and Folder Selection UI

**User Story:** As a user, I want to select API documentation files or folders and code example files or folders separately, so that each file type is properly categorized and placed in the correct directory without needing to select hundreds of individual files.

#### Acceptance Criteria

1. WHEN a user is on the Prepare Source Files step, THE SourceFilesView SHALL display two distinct sections for file/folder selection
2. THE SourceFilesView SHALL provide a separate button or interface element for adding API Documentation Files or Folders
3. THE SourceFilesView SHALL provide a separate button or interface element for adding Code Example Files or Folders
4. WHEN a user clicks the API Documentation button, THE File_Picker SHALL open in folder selection mode with a clear label indicating "Select API Documentation Folder or Files"
5. WHEN a user clicks the Code Example button, THE File_Picker SHALL open in folder selection mode with a clear label indicating "Select Code Examples Folder or Files"
6. WHEN a user selects a folder, THE FileSystemManager SHALL recursively process all .swift files within that folder and its subdirectories
7. WHEN a user selects individual files, THE StepDetailObservable SHALL add only those files to the appropriate category
8. WHEN files or folders are selected through either picker, THE StepDetailObservable SHALL automatically assign the correct Source_File_Category

### Requirement 2: Directory Path Guidance

**User Story:** As a user, I want to understand where files will be placed, so that I can organize my source materials correctly.

#### Acceptance Criteria

1. WHEN displaying the API Documentation section, THE SourceFilesView SHALL show the target directory path `../api_training_data/`
2. WHEN displaying the Code Example section, THE SourceFilesView SHALL show the target directory path `code_examples/`
3. WHEN a user hovers over or taps the directory path, THE SourceFilesView SHALL display a tooltip or expanded view explaining the directory purpose
4. WHEN files are added, THE FileSystemManager SHALL place API Documentation Files in `../api_training_data/`
5. WHEN files are added, THE FileSystemManager SHALL place Code Example Files in `code_examples/`
6. WHEN a user views the file list, THE SourceFilesView SHALL display which directory each file is located in

### Requirement 3: File Type Validation

**User Story:** As a user, I want the system to validate that I'm adding the correct file types, so that I don't accidentally miscategorize files, and to handle bulk folder imports efficiently.

#### Acceptance Criteria

1. WHEN a user selects a folder for API Documentation, THE FileSystemManager SHALL recursively scan for all .swift files
2. WHEN a user selects a folder for Code Examples, THE FileSystemManager SHALL recursively scan for all .swift files
3. WHEN a user selects individual files for API Documentation, THE FileSystemManager SHALL validate that files have a .swift extension
4. WHEN a user selects individual files for Code Examples, THE FileSystemManager SHALL validate that files have a .swift extension
5. IF a user attempts to add a file with an invalid extension, THEN THE SourceFilesView SHALL display an error message indicating the file type is not supported
6. WHEN a user adds a folder, THE FileSystemManager SHALL verify that the folder exists and is readable
7. IF a folder cannot be read or contains no .swift files, THEN THE StepDetailObservable SHALL display an error message with the specific folder path and reason
8. WHEN validation succeeds, THE StepDetailObservable SHALL add all discovered files to the appropriate category list

### Requirement 4: Visual Category Distinction

**User Story:** As a user, I want to visually distinguish between API documentation and code examples in the file list, so that I can quickly understand what type of files I've added.

#### Acceptance Criteria

1. WHEN displaying the file list, THE SourceFilesView SHALL use different icons for API Documentation Files and Code Example Files
2. THE SourceFilesView SHALL display the category label (e.g., "API Documentation" or "Code Examples") for each file
3. WHEN files are grouped by category, THE SourceFilesView SHALL organize the list with API Documentation Files in one section and Code Example Files in another
4. WHEN a user views a file, THE SourceFilesView SHALL display the file size, category, and directory path
5. WHEN a user removes a file, THE SourceFilesView SHALL update the visual display immediately
6. THE SourceFilesView SHALL use consistent visual styling that matches the existing AI Forge design language

### Requirement 5: Category-Specific File Operations

**User Story:** As a user, I want to manage files within each category independently, so that I can add, remove, or organize files by type, including bulk operations from folders.

#### Acceptance Criteria

1. WHEN a user removes an API Documentation File, THE FileSystemManager SHALL delete the file from `../api_training_data/`
2. WHEN a user removes a Code Example File, THE FileSystemManager SHALL delete the file from `code_examples/`
3. WHEN a user adds multiple files from a folder, THE StepDetailObservable SHALL add all files to the same category list
4. WHEN a user adds files from different categories in sequence, THE StepDetailObservable SHALL maintain separate lists for each category
5. WHEN a user views the file list, THE SourceFilesView SHALL display the count of files in each category
6. WHEN a user adds a folder, THE SourceFilesView SHALL display the folder path and the count of files discovered within it
7. WHEN all files are removed from a category, THE SourceFilesView SHALL display an empty state for that category
8. WHEN a user removes a file that was added from a folder, THE FileSystemManager SHALL delete only that individual file, not the entire folder

### Requirement 6: Step Completion Validation

**User Story:** As a user, I want the system to validate that I've added files before proceeding, so that I don't accidentally skip the file preparation step.

#### Acceptance Criteria

1. WHEN a user attempts to complete the Prepare Source Files step, THE StepDetailObservable SHALL verify that at least one file exists in at least one category
2. IF no files have been added, THEN THE SourceFilesView SHALL display a validation error message
3. IF files exist in only one category, THE StepDetailObservable SHALL allow step completion (both categories are not required)
4. WHEN files exist in both categories, THE StepDetailObservable SHALL mark the step as ready for completion
5. WHEN the step is marked complete, THE StepDetailObservable SHALL record which categories contain files for reference by subsequent steps
6. WHEN a user returns to the Prepare Source Files step after completion, THE SourceFilesView SHALL display all previously added files

### Requirement 7: Integration with Python Scripts

**User Story:** As a developer, I want the file organization to align with Python script expectations, so that the dataset generation scripts work correctly.

#### Acceptance Criteria

1. WHEN the generate_optimized_dataset.py script runs, THE FileSystemManager SHALL ensure Code Example Files are in `code_examples/` subdirectories
2. WHEN the generate_unified_dataset.py script runs, THE FileSystemManager SHALL ensure API Documentation Files are in `../api_training_data/`
3. WHEN the generate_unified_dataset.py script runs, THE FileSystemManager SHALL ensure Code Example Files are in `code_examples/` subdirectories
4. WHEN files are organized correctly, THE Python scripts SHALL be able to locate and process all files without errors
5. WHEN a user views the Generate Optimized Dataset step, THE StepDetailObservable SHALL reference the file organization from the Prepare Source Files step
6. IF files are missing or misorganized, THE Python scripts SHALL fail with clear error messages indicating the issue

### Requirement 8: User Guidance and Help

**User Story:** As a user, I want clear guidance on what types of files to add, so that I understand the difference between API documentation and code examples.

#### Acceptance Criteria

1. WHEN a user views the Prepare Source Files step, THE SourceFilesView SHALL display a help section explaining the two file types
2. THE SourceFilesView SHALL provide examples of what constitutes an API Documentation File (e.g., "SwiftUI Framework API.swift")
3. THE SourceFilesView SHALL provide examples of what constitutes a Code Example File (e.g., "Animation examples, data management patterns")
4. WHEN a user hovers over the API Documentation section, THE SourceFilesView SHALL display a tooltip explaining the purpose and content type
5. WHEN a user hovers over the Code Example section, THE SourceFilesView SHALL display a tooltip explaining the purpose and content type
6. THE SourceFilesView SHALL include a link to the Fine Tuning Guide for more detailed information

