# Implementation Plan: Source File Selection Improvement

## Overview

This implementation plan breaks down the source file selection improvement feature into discrete, incremental coding tasks. The feature enhances the AI Forge application to support both individual file selection and bulk folder import for API documentation and code example files, with clear visual distinction and proper directory organization.

The implementation follows the existing SwiftUI patterns in AI Forge, using `@Observable` for state management and maintaining consistency with the Instructions.md guidelines. Tasks are organized to build incrementally, with testing integrated throughout to catch errors early.

## Tasks

- [x] 1. Enhance FileSystemManager with folder scanning and validation
  - Add `findSwiftFiles(in:)` method to recursively discover .swift files in directories
  - Add `isValidSwiftFile(_:)` method to validate file extensions
  - Add `validateFolder(_:)` method to verify folder accessibility
  - Add `validateFileOrFolder(_:)` method for comprehensive validation with error messages
  - Add error handling for inaccessible folders and permission issues
  - _Requirements: 1.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ]* 1.1 Write property test for recursive folder scanning
  - **Property 1: Recursive folder scanning discovers all Swift files**
  - **Validates: Requirements 1.6, 3.1, 3.2**
  - Test discovers all .swift files in nested directories
  - Test filters out non-.swift files correctly
  - Test handles empty subdirectories

- [ ]* 1.2 Write property test for file extension validation
  - **Property 6: File extension validation rejects non-Swift files**
  - **Validates: Requirements 3.3, 3.4, 3.5**
  - Test rejects files with invalid extensions
  - Test accepts .swift files
  - Test handles case-insensitive extensions

- [x] 2. Enhance StepDetailObservable with folder/file handling
  - Add `addSourceFilesOrFolders(_:category:)` async method to handle both files and folders
  - Implement logic to detect whether URL is a file or folder
  - Call FileSystemManager to process folders recursively or add individual files
  - Update sourceFiles list with all discovered files
  - Handle errors and display appropriate error messages
  - _Requirements: 1.7, 1.8, 3.8_

- [ ]* 2.1 Write property test for individual file selection
  - **Property 2: Individual file selection adds only selected files**
  - **Validates: Requirements 1.7**
  - Test that only selected files are added to the list
  - Test that unselected files are not added

- [ ]* 2.2 Write property test for file category assignment
  - **Property 3: File category assignment is correct**
  - **Validates: Requirements 1.8**
  - Test API Documentation files get correct category
  - Test Code Examples files get correct category

- [x] 3. Enhance SourceFilesView with separate category sections
  - Refactor view to display two distinct sections: API Documentation and Code Examples
  - Add separate buttons for each category with appropriate icons and labels
  - Implement `categorySection(title:files:icon:)` helper to display files grouped by category
  - Add `helpSection` to explain the two file types with examples
  - Add `emptyStateView` for when no files are added
  - Implement `directoryPath(for:)` helper method
  - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 8.1, 8.2, 8.3_

- [ ]* 3.1 Write unit test for SourceFilesView category sections
  - Test that both category sections are displayed when files exist
  - Test that empty state is shown when no files exist
  - Test that help section is displayed with correct content
  - Test that file counts are displayed correctly
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4. Implement file picker integration for API Documentation
  - Add `showingAPIDocumentationPicker` state variable to SourceFilesView
  - Configure `.fileImporter` modifier to accept folders and .swift files
  - Set appropriate label for API Documentation picker
  - Implement `handleFileSelection(_:category:)` to call `addSourceFilesOrFolders(_:category:)`
  - _Requirements: 1.4, 1.5_

- [ ]* 4.1 Write unit test for API Documentation file picker
  - Test that file picker opens with correct configuration
  - Test that selected files are added with correct category
  - Test that folder selection works correctly
  - _Requirements: 1.4_

- [x] 5. Implement file picker integration for Code Examples
  - Add `showingCodeExamplesPicker` state variable to SourceFilesView
  - Configure `.fileImporter` modifier to accept folders and .swift files
  - Set appropriate label for Code Examples picker
  - Implement file selection handler for Code Examples category
  - _Requirements: 1.4, 1.5_

- [ ]* 5.1 Write unit test for Code Examples file picker
  - Test that file picker opens with correct configuration
  - Test that selected files are added with correct category
  - Test that folder selection works correctly
  - _Requirements: 1.5_

- [x] 6. Implement file organization in FileSystemManager
  - Ensure API documentation files are placed in `../api_training_data/`
  - Ensure code example files are placed in `code_examples/`
  - Create directories if they don't exist
  - Handle file copying/referencing appropriately
  - Add `addSourceFile(at:to:category:)` method to handle file placement
  - _Requirements: 2.4, 2.5_

- [ ]* 6.1 Write property test for file placement
  - **Property 4: API documentation files are placed in correct directory**
  - **Property 5: Code example files are placed in correct directory**
  - **Validates: Requirements 2.4, 2.5**
  - Test API docs are placed in ../api_training_data/
  - Test code examples are placed in code_examples/

- [x] 7. Implement file removal with proper cleanup
  - Update `removeSourceFile(_:)` to delete files from correct directories
  - Ensure only the specific file is deleted, not the entire folder
  - Update UI immediately after removal
  - Add error handling for file deletion failures
  - _Requirements: 5.1, 5.2, 5.8, 4.5_

- [ ]* 7.1 Write property test for file removal
  - **Property 9: File removal deletes file from file system**
  - **Validates: Requirements 5.1, 5.2, 5.8**
  - Test file is deleted from file system
  - Test file no longer appears in list
  - Test only specific file is deleted, not entire folder

- [x] 8. Implement category-specific file operations and display
  - Display file count for each category in section headers
  - Show empty state when category has no files
  - Maintain separate lists for each category in SourceFilesView
  - Display file size and directory path for each file
  - Implement file removal button with confirmation
  - _Requirements: 5.3, 5.4, 5.5, 5.6, 5.7, 4.5_

- [ ]* 8.1 Write property test for category separation
  - **Property 7: Multiple files from folder are all added to same category**
  - **Property 8: Files from different categories remain separate**
  - **Validates: Requirements 5.3, 5.4**
  - Test all files from folder go to same category
  - Test files from different categories don't mix

- [ ]* 8.2 Write property test for empty category display
  - **Property 10: Empty category displays empty state**
  - **Validates: Requirements 5.7**
  - Test empty category shows no files
  - Test empty state is displayed correctly

- [ ]* 8.3 Write unit test for category display
  - Test that file counts are displayed correctly
  - Test that file sizes are formatted properly
  - Test that directory paths are shown
  - _Requirements: 5.5, 5.6_

- [x] 9. Implement step completion validation
  - Add validation logic to verify at least one file exists before allowing step completion
  - Allow completion with files in only one category
  - Record which categories contain files
  - Display validation error if no files exist
  - Update step status based on file presence
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 9.1 Write property test for step completion validation
  - **Property 11: Step completion requires at least one file**
  - **Property 12: Step completion allowed with files in one category**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**
  - Test step fails with zero files
  - Test step succeeds with files in one category
  - Test step succeeds with files in both categories

- [ ]* 9.2 Write unit test for step completion
  - Test validation error message when no files exist
  - Test that step can be completed with files in one category
  - Test that step can be completed with files in both categories
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 10. Implement file persistence across step navigation
  - Ensure files persist when user returns to Prepare Source Files step
  - Load previously added files when step is revisited
  - Maintain file organization and category assignments
  - Add `loadSourceFiles()` method to reload files from disk
  - _Requirements: 6.6_

- [ ]* 10.1 Write property test for file persistence
  - **Property 13: Category information persists after step completion**
  - **Validates: Requirements 6.5, 6.6**
  - Test files persist after step completion
  - Test categories are maintained
  - Test file list is restored on revisit

- [x] 11. Add directory path display and guidance
  - Display target directory paths in each category section header
  - Add help text explaining directory purposes
  - Show directory path for each file in the list
  - Implement `directoryPath(for:)` helper method
  - _Requirements: 2.1, 2.2, 2.3, 2.6_

- [ ]* 11.1 Write unit test for directory path display
  - Test that correct paths are displayed for each category
  - Test that file list shows directory information
  - Test that help text is displayed
  - _Requirements: 2.1, 2.2, 2.6_

- [x] 12. Add user guidance and help content
  - Display help section explaining API documentation vs code examples
  - Provide examples of each file type
  - Add tooltips or help text explaining directory purposes
  - Include link to Fine Tuning Guide
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ]* 12.1 Write unit test for help content
  - Test that help section is displayed
  - Test that examples are shown
  - Test that tooltips appear on hover
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 13. Verify Python script integration compatibility
  - Ensure file organization matches Python script expectations
  - Verify that generate_optimized_dataset.py can find code examples in code_examples/
  - Verify that generate_unified_dataset.py can find API docs in ../api_training_data/
  - Verify that generate_unified_dataset.py can find code examples in code_examples/
  - Document file organization for Python scripts
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [ ]* 13.1 Write property test for Python script compatibility
  - **Property 14: File organization matches Python script expectations**
  - **Validates: Requirements 7.1, 7.2, 7.3, 7.5**
  - Test API docs are in correct location for Python scripts
  - Test code examples are in correct location for Python scripts

- [x] 14. Checkpoint - Ensure all tests pass
  - Run all unit tests and verify they pass
  - Run all property-based tests with minimum 100 iterations each
  - Verify no regressions in existing functionality
  - Ask the user if questions arise

- [ ] 15. Integration testing with existing workflow
  - Test that SourceFilesView integrates correctly with StepDetailView
  - Test that file selection works with existing project structure
  - Test that subsequent steps can access file organization information
  - Verify that Python scripts can locate and process organized files
  - Test complete workflow from file selection through step completion
  - _Requirements: 1.1, 2.1, 6.6, 7.1, 7.2, 7.3_

- [ ] 16. Final checkpoint - Ensure all tests pass and feature is complete
  - Run all tests one final time
  - Verify all requirements are met
  - Check that design properties are validated
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests should run with minimum 100 iterations to ensure comprehensive coverage
- Unit tests should focus on specific examples and edge cases
- Integration tests verify that components work together correctly
- Checkpoints ensure incremental validation and catch errors early
- All code should follow the Instructions.md guidelines for SwiftUI and Swift development
- Existing test files (FileSystemPropertyTests.swift and FileValidationTests.swift) provide patterns for new tests
