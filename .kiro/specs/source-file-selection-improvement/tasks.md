# Implementation Plan: Source File Selection Improvement

## Overview

This implementation plan breaks down the source file selection improvement feature into discrete, incremental coding tasks. The feature enhances the AI Forge application to support both individual file selection and bulk folder import for API documentation and code example files, with clear visual distinction and proper directory organization.

The implementation follows the existing SwiftUI patterns in AI Forge, using `@Observable` for state management and maintaining consistency with the Instructions.md guidelines. Tasks are organized to build incrementally, with testing integrated throughout to catch errors early.

## Tasks

- [x] 1. Enhance FileSystemManager with folder scanning capability
  - Add `findSwiftFiles(in:)` method to recursively discover .swift files in directories
  - Implement file validation to ensure only .swift files are processed
  - Add error handling for inaccessible folders and permission issues
  - _Requirements: 1.6, 3.1, 3.2_

- [ ]* 1.1 Write property test for recursive folder scanning
  - **Property 1: Recursive folder scanning discovers all Swift files**
  - **Validates: Requirements 1.6, 3.1, 3.2**

- [x] 2. Enhance StepDetailObservable with folder/file handling
  - Add `addSourceFilesOrFolders(_:category:)` method to handle both files and folders
  - Implement logic to detect whether URL is a file or folder
  - Call FileSystemManager to process folders recursively or add individual files
  - Update sourceFiles list with all discovered files
  - _Requirements: 1.7, 1.8, 3.8_

- [ ]* 2.1 Write property test for file category assignment
  - **Property 3: File category assignment is correct**
  - **Validates: Requirements 1.8**

- [ ]* 2.2 Write property test for individual file selection
  - **Property 2: Individual file selection adds only selected files**
  - **Validates: Requirements 1.7**

- [x] 3. Enhance SourceFilesView with separate category sections
  - Refactor view to display two distinct sections: API Documentation and Code Examples
  - Add separate buttons for each category with appropriate icons and labels
  - Implement `categorySection(title:files:icon:)` helper to display files grouped by category
  - Add help section explaining the two file types with examples
  - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 8.1, 8.2, 8.3_

- [ ]* 3.1 Write unit test for SourceFilesView category sections
  - Test that both category sections are displayed when files exist
  - Test that empty state is shown when no files exist
  - Test that help section is displayed with correct content
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4. Implement file picker integration for API Documentation
  - Add `showingAPIDocumentationPicker` state variable
  - Configure file importer to accept folders and .swift files
  - Set appropriate label for API Documentation picker
  - Call `addSourceFilesOrFolders(_:category:)` with `.apiDocumentation` category
  - _Requirements: 1.4, 1.5_

- [ ]* 4.1 Write unit test for API Documentation file picker
  - Test that file picker opens with correct configuration
  - Test that selected files are added with correct category
  - _Requirements: 1.4_

- [x] 5. Implement file picker integration for Code Examples
  - Add `showingCodeExamplesPicker` state variable
  - Configure file importer to accept folders and .swift files
  - Set appropriate label for Code Examples picker
  - Call `addSourceFilesOrFolders(_:category:)` with `.codeExamples` category
  - _Requirements: 1.4, 1.5_

- [ ]* 5.1 Write unit test for Code Examples file picker
  - Test that file picker opens with correct configuration
  - Test that selected files are added with correct category
  - _Requirements: 1.5_

- [x] 6. Add directory path display and guidance
  - Display target directory paths in each category section
  - Add tooltips or help text explaining directory purposes
  - Show directory path for each file in the list
  - Implement `directoryPath(for:)` helper method
  - _Requirements: 2.1, 2.2, 2.3, 2.6_

- [ ]* 6.1 Write unit test for directory path display
  - Test that correct paths are displayed for each category
  - Test that file list shows directory information
  - _Requirements: 2.1, 2.2, 2.6_

- [x] 7. Implement file validation and error handling
  - Add validation in FileSystemManager to check file extensions
  - Display error messages for invalid file types
  - Handle folder access errors gracefully
  - Display specific error messages with file/folder names
  - _Requirements: 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ]* 7.1 Write property test for file extension validation
  - **Property 6: File extension validation rejects non-Swift files**
  - **Validates: Requirements 3.3, 3.4, 3.5**

- [ ]* 7.2 Write unit test for error handling
  - Test error messages for invalid file types
  - Test error messages for inaccessible folders
  - _Requirements: 3.5, 3.6, 3.7_

- [x] 8. Implement file organization in FileSystemManager
  - Ensure API documentation files are placed in `../api_training_data/`
  - Ensure code example files are placed in `code_examples/`
  - Create directories if they don't exist
  - Handle file copying/referencing appropriately
  - _Requirements: 2.4, 2.5_

- [ ]* 8.1 Write property test for file placement
  - **Property 4: API documentation files are placed in correct directory**
  - **Property 5: Code example files are placed in correct directory**
  - **Validates: Requirements 2.4, 2.5**

- [ ] 9. Implement file removal with proper cleanup
  - Update `removeSourceFile(_:)` to delete files from correct directories
  - Ensure only the specific file is deleted, not the entire folder
  - Update UI immediately after removal
  - _Requirements: 5.1, 5.2, 5.8, 4.5_

- [ ]* 9.1 Write property test for file removal
  - **Property 9: File removal deletes file from file system**
  - **Validates: Requirements 5.1, 5.2, 5.8**

- [ ]* 9.2 Write property test for UI update on removal
  - **Property 15: UI updates immediately when file is removed**
  - **Validates: Requirements 4.5**

- [ ] 10. Implement category-specific file operations
  - Display file count for each category
  - Show empty state when category has no files
  - Maintain separate lists for each category
  - Display folder path and file count when folder is added
  - _Requirements: 5.3, 5.4, 5.5, 5.6, 5.7_

- [ ]* 10.1 Write property test for category separation
  - **Property 7: Multiple files from folder are all added to same category**
  - **Property 8: Files from different categories remain separate**
  - **Validates: Requirements 5.3, 5.4**

- [ ]* 10.2 Write property test for empty category display
  - **Property 10: Empty category displays empty state**
  - **Validates: Requirements 5.7**

- [ ]* 10.3 Write unit test for category display
  - Test that file counts are displayed correctly
  - Test that folder information is displayed
  - _Requirements: 5.5, 5.6_

- [ ] 11. Implement step completion validation
  - Verify at least one file exists before allowing step completion
  - Allow completion with files in only one category
  - Record which categories contain files
  - Display validation error if no files exist
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 11.1 Write property test for step completion validation
  - **Property 11: Step completion requires at least one file**
  - **Property 12: Step completion allowed with files in one category**
  - **Property 13: Category information persists after step completion**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [ ]* 11.2 Write unit test for step completion
  - Test validation error when no files exist
  - Test that step can be completed with files in one category
  - Test that step can be completed with files in both categories
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 12. Implement file persistence across step navigation
  - Ensure files persist when user returns to Prepare Source Files step
  - Load previously added files when step is revisited
  - Maintain file organization and category assignments
  - _Requirements: 6.6_

- [ ]* 12.1 Write property test for file persistence
  - **Property 13: Category information persists after step completion**
  - **Validates: Requirements 6.5, 6.6**

- [ ] 13. Verify Python script integration compatibility
  - Ensure file organization matches Python script expectations
  - Verify that generate_optimized_dataset.py can find code examples
  - Verify that generate_unified_dataset.py can find both API docs and code examples
  - Document file organization for Python scripts
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [ ]* 13.1 Write property test for Python script compatibility
  - **Property 14: File organization matches Python script expectations**
  - **Validates: Requirements 7.1, 7.2, 7.3, 7.5**

- [ ] 14. Add user guidance and help content
  - Display help section explaining API documentation vs code examples
  - Provide examples of each file type
  - Add tooltips for directory paths
  - Include link to Fine Tuning Guide
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ]* 14.1 Write unit test for help content
  - Test that help section is displayed
  - Test that examples are shown
  - Test that tooltips appear on hover
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ] 15. Checkpoint - Ensure all tests pass
  - Run all unit tests and verify they pass
  - Run all property-based tests with minimum 100 iterations each
  - Verify no regressions in existing functionality
  - Ask the user if questions arise

- [ ] 16. Integration testing with existing workflow
  - Test that SourceFilesView integrates correctly with StepDetailView
  - Test that file selection works with existing project structure
  - Test that subsequent steps can access file organization information
  - Verify that Python scripts can locate and process organized files
  - _Requirements: 1.1, 2.1, 6.6, 7.1, 7.2, 7.3_

- [ ] 17. Final checkpoint - Ensure all tests pass and feature is complete
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
