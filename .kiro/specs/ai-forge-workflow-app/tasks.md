# Implementation Plan: AI Forge Workflow Application

## Overview

This implementation plan breaks down the AI Forge Workflow Application into discrete, manageable coding tasks. The application is a macOS SwiftUI app that guides users through fine-tuning AI models across any knowledge domain. The implementation follows a layered architecture approach: Data Layer → Business Logic Layer → Presentation Layer → Testing.

Each task builds incrementally on previous work, with property-based tests integrated close to implementation to catch errors early. Tasks marked with `*` are optional and can be skipped for faster MVP delivery.

## Tasks

- [x] 1. Set up project structure and core infrastructure
  - Create Xcode project for macOS SwiftUI application (minimum macOS 14.0)
  - Set up folder structure: App/, Views/, Shared/ (Models, Services, Extensions, Tools), Resources/, Supporting Files/
  - Configure SwiftData model container in app entry point
  - Add file header template to all new files: `// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio`
  - _Requirements: All requirements (foundation)_

- [x] 2. Implement data models (SwiftData layer)
  - [x] 2.1 Create StepStatus enum and WorkflowStepModel
    - Define `StepStatus` enum with cases: pending, inProgress, completed, failed
    - Create `WorkflowStepModel` with @Model macro
    - Add properties: id, stepNumber, title, stepDescription, status, completedAt, errorMessage
    - Implement `createDefaultSteps()` static method to generate six workflow steps
    - Add computed properties: `viewStatusIcon`, `viewStatusColor`
    - Add preview helpers: `mock` static property
    - _Requirements: 3.1, 3.3_

  - [ ]* 2.2 Write property test for WorkflowStepModel
    - **Property 13: Step State Preservation During Navigation**
    - **Validates: Requirements 3.6**

  - [x] 2.3 Create FineTuningConfigurationModel
    - Create `FineTuningConfigurationModel` with @Model macro
    - Add properties: id, modelName, learningRate, batchSize, numberOfEpochs, outputDirectory, datasetPath, additionalParameters
    - Implement validation methods: `isValid`, `validate()`
    - Define `ConfigurationError` enum with validation error cases
    - Add preview helper: `mock` static property
    - _Requirements: 6.2, 6.3_

  - [ ]* 2.4 Write property test for configuration validation
    - **Property 23: Configuration Value Validation**
    - **Validates: Requirements 6.3**

  - [ ]* 2.5 Write property test for configuration persistence
    - **Property 24: Configuration Persistence Round-Trip**
    - **Validates: Requirements 6.4, 6.5**

  - [x] 2.6 Create ProjectModel
    - Create `ProjectModel` with @Model macro
    - Add properties: id (unique), name, domainName, domainDescription, createdAt, updatedAt, currentStepIndex, projectDirectoryPath
    - Add relationships: workflowSteps (one-to-many, cascade delete), configuration (one-to-one, cascade delete)
    - Initialize with default workflow steps in init
    - Add computed properties: `viewCurrentStepTitle`, `viewProgressPercentage`
    - Add preview helpers: `mock`, `mocks`, `preview` (ModelContainer)
    - _Requirements: 1.1, 2.2, 3.1_

  - [ ]* 2.7 Write property test for project initialization
    - **Property 1: Project Creation Initializes State**
    - **Validates: Requirements 1.1**

  - [ ]* 2.8 Write property test for domain information persistence
    - **Property 8: Domain Information Persistence**
    - **Validates: Requirements 2.2**

  - [x] 2.9 Create SourceFileReference struct
    - Create `SourceFileReference` struct (Codable, Identifiable)
    - Add properties: id, fileName, filePath, fileSize, category, addedAt
    - Define `SourceFileCategory` enum: apiDocumentation, codeExamples
    - Add computed property: `viewFileSizeFormatted` using ByteCountFormatter
    - Add preview helpers: `mock`, `mocks`
    - _Requirements: 4.1, 4.4_

- [x] 3. Checkpoint - Ensure data models compile
  - Ensure all data models compile without errors, ask the user if questions arise.

- [x] 4. Implement service layer (Business logic)
  - [x] 4.1 Create FileSystemManager
    - Create `FileSystemManager` class with FileManager instance
    - Initialize with base projects directory in Application Support
    - Implement `createProjectDirectory(projectName:)` - creates root and subdirectories
    - Implement `createProjectSubdirectories(projectRoot:)` - creates source/, datasets/, models/, config/, logs/ subdirectories
    - Implement `addSourceFile(at:to:category:)` - copies file and returns SourceFileReference
    - Implement `removeSourceFile(_:)` - deletes file from project
    - Implement `listSourceFiles(in:category:)` - returns array of SourceFileReference
    - Implement `validateFilePath(_:)` - checks file existence
    - Implement `deleteProjectDirectory(at:)` - removes entire project directory
    - Implement `getProjectDirectory(projectName:)` - returns project URL
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 11.1, 11.2, 11.3_

  - [ ]* 4.2 Write property test for directory structure creation
    - **Property 3: Project Directory Structure Creation**
    - **Validates: Requirements 1.3, 11.1, 11.2**

  - [ ]* 4.3 Write property test for source file operations
    - **Property 14: Source File Addition**
    - **Property 15: Source File Validation**
    - **Property 17: Source File Removal**
    - **Validates: Requirements 4.2, 4.3, 4.5**

  - [ ]* 4.4 Write property test for file placement
    - **Property 31: File Placement in Correct Subdirectories**
    - **Validates: Requirements 11.3**

  - [x] 4.5 Create PythonScriptExecutor actor
    - Create `PythonScriptExecutor` actor for thread-safe script execution
    - Add property: `currentProcess` (optional Process)
    - Implement `executeScript(scriptPath:arguments:workingDirectory:outputHandler:)` async method
    - Set up Process with python3 executable, arguments, working directory
    - Create Pipes for stdout and stderr
    - Implement readability handlers to capture output and call outputHandler
    - Wait for process completion and capture exit code
    - Return `ScriptExecutionResult` with exitCode, output, error, success
    - Implement `cancelExecution()` async method to terminate current process
    - Implement `verifyPythonInstallation()` async method
    - Define `ScriptExecutionResult` struct
    - _Requirements: 5.1, 7.1, 7.3, 8.1, 9.1, 12.1, 12.2, 12.3, 12.4, 12.6_

  - [ ]* 4.6 Write property test for script execution
    - **Property 19: Python Script Execution with Parameters**
    - **Property 36: Script Argument Passing**
    - **Property 37: Output Stream Capture**
    - **Property 38: Exit Code Handling**
    - **Property 40: Working Directory Configuration**
    - **Validates: Requirements 5.1, 7.1, 8.1, 9.1, 12.2, 12.3, 12.4, 12.6**

  - [ ]* 4.7 Write unit test for Python installation verification
    - Test `verifyPythonInstallation()` with mock process
    - Test error handling when Python is not found
    - _Requirements: 12.1_

- [x] 5. Checkpoint - Ensure service layer compiles
  - Ensure all service classes compile without errors, ask the user if questions arise.

- [x] 6. Implement observable classes (State management)
  - [x] 6.1 Create ProjectManagerObservable
    - Create `ProjectManagerObservable` class with @Observable macro
    - Add properties: modelContext, fileSystemManager, projects array, selectedProject, isLoading, errorMessage
    - Implement `createProject(name:domainName:domainDescription:)` async method
    - Validate project name using `validateProjectName(_:)` helper
    - Create project directory via FileSystemManager
    - Create ProjectModel and insert into SwiftData context
    - Implement `loadProjects()` async method using FetchDescriptor
    - Implement `deleteProject(_:)` async method
    - Implement `saveProject(_:)` method
    - Implement `validateProjectName(_:)` helper returning ValidationResult
    - Define `ValidationResult` struct and `ProjectError` enum
    - _Requirements: 1.1, 1.2, 1.4, 1.6, 1.7_

  - [ ]* 6.2 Write property test for project name validation
    - **Property 2: Project Name Validation Rejects Invalid Characters**
    - **Validates: Requirements 1.2**

  - [ ]* 6.3 Write property test for project CRUD operations
    - **Property 4: Project List Completeness**
    - **Property 6: Project Persistence Round-Trip**
    - **Property 7: Project Deletion Removes from List**
    - **Validates: Requirements 1.4, 1.6, 1.7, 10.4, 10.5**

  - [x] 6.4 Create WorkflowEngineObservable
    - Create `WorkflowEngineObservable` class with @Observable macro
    - Add properties: modelContext, pythonExecutor, fileSystemManager, currentProject, currentStep, isExecutingStep, executionOutput
    - Implement `loadProject(_:)` method to set current project and step
    - Implement `canProgressToNextStep()` method checking current step completion
    - Implement `progressToNextStep()` method incrementing step index
    - Implement `markStepComplete(_:)` method updating step status and timestamp
    - Implement `markStepFailed(_:error:)` method setting error message
    - Implement `retryStep(_:)` method resetting step to pending
    - Define `WorkflowError` enum
    - _Requirements: 3.4, 3.5, 3.6_

  - [ ]* 6.5 Write property test for workflow progression
    - **Property 11: Step Completion Enables Next Step**
    - **Property 12: Prerequisite Enforcement**
    - **Validates: Requirements 3.4, 3.5**

  - [x] 6.6 Create StepDetailObservable
    - Create `StepDetailObservable` class with @Observable macro
    - Add properties: workflowEngine, fileSystemManager, pythonExecutor, currentStep, currentProject, sourceFiles, configuration, executionOutput, isExecuting, errorMessage
    - Implement `loadStep(_:project:)` async method
    - Load step-specific data based on step number (source files for step 1, configuration for step 3)
    - Implement `addSourceFiles(_:)` async method using FileSystemManager
    - Implement `removeSourceFile(_:)` async method
    - Implement `updateConfiguration(_:)` async method
    - Implement `executeStep()` async method
    - Call `executeStepScript(step:project:)` helper
    - Mark step complete or failed based on result
    - Implement `cancelExecution()` async method
    - Implement private `loadSourceFiles()` async helper
    - Implement private `executeStepScript(step:project:)` async helper
    - Implement private `getScriptPath(for:)` helper
    - Implement private `getScriptArguments(for:project:)` helper
    - _Requirements: 4.2, 4.5, 5.1, 6.4, 7.1, 7.3, 8.1, 9.1_

  - [ ]* 6.7 Write property test for step execution
    - **Property 20: Script Success Marks Step Complete**
    - **Property 21: Script Failure Marks Step Failed**
    - **Property 26: Process Cancellation**
    - **Validates: Requirements 5.3, 5.4, 7.3, 7.4, 7.5, 8.3, 8.4, 9.3, 9.4**

- [x] 7. Checkpoint - Ensure observable classes compile
  - Ensure all observable classes compile without errors, ask the user if questions arise.

- [x] 8. Implement presentation layer (SwiftUI views)
  - [x] 8.1 Create AIForgeApp entry point
    - Create `AIForgeApp` struct with @main attribute
    - Define WindowGroup scene with ContentView
    - Configure modelContainer for ProjectModel, WorkflowStepModel, FineTuningConfigurationModel
    - Add file header
    - _Requirements: All (foundation)_

  - [x] 8.2 Create ContentView (main layout)
    - Create `ContentView` with NavigationSplitView
    - Add @Environment(\.modelContext) property
    - Add @State properties: projectManager, selectedProject
    - Sidebar: ProjectListView with projectManager and selectedProject binding
    - Detail: WorkflowView if project selected, placeholder text otherwise
    - Implement `createProjectManager()` helper
    - Add #Preview with ProjectModel.preview
    - _Requirements: 13.1, 13.2_

  - [x] 8.3 Create ProjectListView
    - Create `ProjectListView` with List of projects
    - Add @Bindable projectManager and @Binding selectedProject
    - Add @State showingCreateProject for sheet presentation
    - Display ProjectRowView for each project with selection binding
    - Add toolbar with "New Project" button
    - Present ProjectCreationView sheet
    - Call `projectManager.loadProjects()` in .task modifier
    - Add #Preview
    - _Requirements: 1.4, 1.5, 13.1_

  - [x] 8.4 Create ProjectRowView
    - Create `ProjectRowView` displaying project information
    - Show project name (headline), domain name (subheadline)
    - Show current step progress: "Step X of 6"
    - Show progress bar using `project.viewProgressPercentage`
    - Add vertical padding
    - _Requirements: 15.4_

  - [x] 8.5 Create ProjectCreationView
    - Create `ProjectCreationView` with Form
    - Add @Environment(\.dismiss) and @Bindable projectManager
    - Add @State properties: projectName, domainName, domainDescription, isCreating, errorMessage
    - Form section with TextFields for project info
    - Display error message if present
    - Toolbar with Cancel and Create buttons
    - Implement `createProject()` method calling projectManager
    - Disable Create button if fields empty or isCreating
    - Add #Preview
    - _Requirements: 1.1, 1.2, 2.1, 2.2_

  - [x] 8.6 Create WorkflowView
    - Create `WorkflowView` with NavigationStack
    - Add project parameter and @State properties: workflowEngine, selectedStep
    - Display List of workflow steps with NavigationLink
    - Show WorkflowStepRowView for each step
    - Add navigationDestination for WorkflowStepModel showing StepDetailView
    - Implement `createWorkflowEngine()` helper
    - Load project in workflowEngine on appear
    - Add #Preview
    - _Requirements: 3.1, 13.2, 13.3_

  - [x] 8.7 Create WorkflowStepRowView
    - Create `WorkflowStepRowView` displaying step information
    - Show status icon using `step.viewStatusIcon` with color
    - Show step title (headline) and description (subheadline)
    - Show completion timestamp if available
    - Implement `colorForStatus(_:)` helper
    - Add vertical padding
    - _Requirements: 3.3, 15.6_

  - [x] 8.8 Create StepDetailView
    - Create `StepDetailView` with ScrollView
    - Add parameters: step, project, workflowEngine
    - Add @State stepObservable property
    - Display step header with title and description
    - Display step-specific content using `stepContent(for:observable:)` helper
    - Display execution output in scrollable monospaced text view
    - Display error message if present
    - Display action buttons: Execute Step, Retry, Cancel
    - Show ProgressView when executing
    - Implement `stepContent(for:observable:)` ViewBuilder
    - Create stepObservable on appear and load step
    - Add #Preview
    - _Requirements: 3.3, 5.2, 7.2, 8.2, 9.2, 13.3_

  - [x] 8.9 Create SourceFilesView (step 1 content)
    - Create `SourceFilesView` displaying source file list
    - Add observable parameter (StepDetailObservable)
    - Display List of source files with file name, size, category
    - Add toolbar button to add files using file picker
    - Add swipe-to-delete for removing files
    - Show empty state when no files
    - _Requirements: 4.1, 4.4, 4.5_

  - [x] 8.10 Create ConfigurationView (step 3 content)
    - Create `ConfigurationView` with Form
    - Add observable parameter (StepDetailObservable)
    - Display TextField for model name
    - Display TextField for learning rate (with number formatter)
    - Display Stepper for batch size
    - Display Stepper for number of epochs
    - Display TextField for output directory with folder picker
    - Display TextField for dataset path with file picker
    - Add Save button calling `observable.updateConfiguration()`
    - Show validation errors inline
    - _Requirements: 6.1, 6.2, 6.3_

- [x] 9. Checkpoint - Ensure UI compiles and runs
  - Build and run the application, verify basic navigation works, ask the user if questions arise.

- [x] 10. Implement error handling and validation
  - [x] 10.1 Create ValidationHelpers utility
    - Create `ValidationHelpers` class with static validation methods
    - Implement `isValidProjectName(_:)` checking for empty and invalid characters
    - Implement `isValidFilePath(_:)` checking path validity
    - Implement `isValidLearningRate(_:)` checking positive value
    - Implement `isValidBatchSize(_:)` checking positive integer
    - Implement `isValidEpochs(_:)` checking positive integer
    - _Requirements: 1.2, 6.3, 14.4_

  - [x] 10.2 Add error handling to ProjectManagerObservable
    - Wrap all operations in do-catch blocks
    - Set errorMessage property on failures
    - Provide specific error messages with context
    - _Requirements: 14.1, 14.3_

  - [x] 10.3 Add error handling to StepDetailObservable
    - Wrap script execution in do-catch blocks
    - Display stderr output on script failures
    - Provide actionable error messages
    - _Requirements: 14.2, 14.6_

  - [x] 10.4 Add error logging infrastructure
    - Create log directory: ~/Library/Logs/AIForge/
    - Implement logging function with timestamp, category, severity
    - Log all critical errors with stack traces
    - _Requirements: 14.5_

  - [ ]* 10.5 Write unit tests for error handling
    - Test error message generation for various failure scenarios
    - Test validation error display
    - Test error recovery mechanisms
    - _Requirements: 14.1, 14.2, 14.3, 14.4_

- [ ] 11. Implement state persistence and auto-save
  - [ ] 11.1 Add auto-save to WorkflowEngineObservable
    - Call modelContext.save() after marking step complete
    - Call modelContext.save() after step failure
    - Add error handling for save failures
    - _Requirements: 10.1_

  - [ ] 11.2 Add auto-save to ProjectManagerObservable
    - Implement debounced save on configuration changes
    - Save project state on step progression
    - _Requirements: 10.2_

  - [ ] 11.3 Add application shutdown handling
    - Implement applicationWillTerminate handler
    - Ensure all pending saves complete before exit
    - _Requirements: 10.3_

  - [ ]* 11.4 Write property test for auto-save
    - **Property 28: Automatic State Persistence on Step Completion**
    - **Validates: Requirements 10.1**

  - [ ]* 11.5 Write property test for save failure handling
    - **Property 30: Save Failure Error Handling**
    - **Validates: Requirements 10.6**

- [ ] 12. Checkpoint - Test complete workflow
  - Manually test creating a project, adding source files, progressing through steps, ask the user if questions arise.

- [ ] 13. Implement remaining property-based tests
  - [ ]* 13.1 Write property test for project selection
    - **Property 5: Project Selection Loads State**
    - **Validates: Requirements 1.5**

  - [ ]* 13.2 Write property test for custom paths
    - **Property 9: Custom Path Acceptance**
    - **Validates: Requirements 2.4**

  - [ ]* 13.3 Write property test for workflow step display
    - **Property 10: Workflow Step Status Display**
    - **Validates: Requirements 3.3**

  - [ ]* 13.4 Write property test for source file list
    - **Property 16: Source File List Accuracy**
    - **Validates: Requirements 4.4**

  - [ ]* 13.5 Write property test for source file prerequisite
    - **Property 18: Source File Prerequisite Validation**
    - **Validates: Requirements 4.6**

  - [ ]* 13.6 Write property test for output file validation
    - **Property 22: Output File Validation After Generation**
    - **Validates: Requirements 5.5, 7.6**

  - [ ]* 13.7 Write property test for configuration save
    - **Property 25: Configuration Save Completes Step**
    - **Validates: Requirements 6.6**

  - [ ]* 13.8 Write property test for evaluation metrics
    - **Property 27: Evaluation Metrics Display**
    - **Validates: Requirements 8.2**

  - [ ]* 13.9 Write property test for shutdown persistence
    - **Property 29: Application Shutdown Persistence**
    - **Validates: Requirements 10.3**

  - [ ]* 13.10 Write property test for absolute paths
    - **Property 32: Absolute Path Resolution**
    - **Validates: Requirements 11.4**

  - [ ]* 13.11 Write property test for directory cleanup
    - **Property 33: Project Directory Cleanup on Deletion**
    - **Validates: Requirements 11.5**

  - [ ]* 13.12 Write property test for macOS path validation
    - **Property 34: macOS Path Validation**
    - **Validates: Requirements 11.6**

  - [ ]* 13.13 Write property test for Python verification
    - **Property 35: Python Installation Verification**
    - **Validates: Requirements 12.1**

  - [ ]* 13.14 Write property test for missing script error
    - **Property 39: Missing Script Error Handling**
    - **Validates: Requirements 12.5**

  - [ ]* 13.15 Write property test for UI updates
    - **Property 41: Project Selection Updates Detail View**
    - **Property 42: Step Selection Shows Details**
    - **Validates: Requirements 13.2, 13.3**

  - [ ]* 13.16 Write property test for error display
    - **Property 43: Error Message Display on Workflow Errors**
    - **Property 44: Script Error Output Display**
    - **Property 45: File Operation Error Details**
    - **Validates: Requirements 14.1, 14.2, 14.3**

  - [ ]* 13.17 Write property test for error logging
    - **Property 46: Error Logging**
    - **Validates: Requirements 14.5**

  - [ ]* 13.18 Write property test for progress display
    - **Property 47: Project List Shows Current Step**
    - **Property 48: Completion Timestamp Display**
    - **Validates: Requirements 15.4, 15.6**

- [ ] 14. Implement unit tests for edge cases
  - [ ]* 14.1 Write unit tests for ProjectModel
    - Test model initialization with default values
    - Test relationship cascade deletes
    - Test computed properties
    - Test preview helpers
    - _Requirements: 1.1, 3.1_

  - [ ]* 14.2 Write unit tests for WorkflowStepModel
    - Test default steps creation
    - Test status transitions
    - Test computed properties
    - _Requirements: 3.1, 3.3_

  - [ ]* 14.3 Write unit tests for FineTuningConfigurationModel
    - Test validation with boundary values
    - Test validation error messages
    - Test default configuration
    - _Requirements: 6.2, 6.3_

  - [ ]* 14.4 Write unit tests for FileSystemManager
    - Test directory creation with temporary directories
    - Test file operations with mock files
    - Test error handling for permission denied
    - Test cleanup operations
    - _Requirements: 4.2, 4.3, 11.1, 11.2_

  - [ ]* 14.5 Write unit tests for PythonScriptExecutor
    - Test script execution with mock process
    - Test output capture
    - Test cancellation
    - Test Python verification
    - _Requirements: 5.1, 7.1, 7.3, 12.1_

  - [ ]* 14.6 Write unit tests for ProjectManagerObservable
    - Test project creation with various inputs
    - Test project loading and filtering
    - Test project deletion
    - Test validation logic
    - _Requirements: 1.1, 1.2, 1.4, 1.7_

  - [ ]* 14.7 Write unit tests for WorkflowEngineObservable
    - Test step progression logic
    - Test prerequisite checking
    - Test step status updates
    - _Requirements: 3.4, 3.5_

  - [ ]* 14.8 Write unit tests for StepDetailObservable
    - Test step loading
    - Test source file management
    - Test configuration updates
    - Test script execution coordination
    - _Requirements: 4.2, 4.5, 6.4_

- [ ] 15. Implement integration tests
  - [ ]* 15.1 Write integration test for complete project lifecycle
    - Test create → modify → save → load → delete flow
    - Use in-memory SwiftData container
    - Verify state preservation at each step
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 15.2 Write integration test for workflow execution
    - Test complete workflow from step 1 to step 6
    - Use mock Python scripts
    - Verify step progression and state updates
    - _Requirements: 3.1, 3.4, 3.5, 3.6_

  - [ ]* 15.3 Write integration test for file operations
    - Test adding, listing, and removing source files
    - Use temporary directories
    - Verify file system state
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

  - [ ]* 15.4 Write integration test for configuration management
    - Test configuration creation, modification, validation, persistence
    - Verify configuration affects script execution
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 16. Polish UI and add final touches
  - [ ] 16.1 Add keyboard shortcuts
    - Cmd+N for new project
    - Cmd+W to close window
    - Cmd+S to save (if applicable)
    - _Requirements: 13.5_

  - [ ] 16.2 Add accessibility labels
    - Add accessibility labels to all interactive elements
    - Test with VoiceOver
    - _Requirements: 13.6_

  - [ ] 16.3 Add loading states and animations
    - Add skeleton views for loading states
    - Add smooth transitions between views
    - Add progress animations for long operations
    - _Requirements: 13.6, 15.2_

  - [ ] 16.4 Add empty states
    - Add empty state for project list
    - Add empty state for source files
    - Add helpful messages and call-to-action buttons
    - _Requirements: 13.1_

  - [ ] 16.5 Improve error messages
    - Review all error messages for clarity
    - Add suggestions for common errors
    - Add links to documentation where helpful
    - _Requirements: 14.1, 14.6_

- [ ] 17. Final checkpoint - Complete testing and verification
  - Run all unit tests and verify 80%+ code coverage
  - Run all property-based tests (100 iterations each)
  - Run all integration tests
  - Manually test all user workflows
  - Verify error handling for all failure scenarios
  - Test with various project configurations
  - Ensure all requirements are met

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Property-based tests validate universal correctness properties with 100+ iterations
- Unit tests validate specific examples, edge cases, and error conditions
- Integration tests validate complete workflows and component interactions
- All tests use Swift Testing framework with custom property-based testing utilities
- SwiftData tests use in-memory model containers for isolation
- File system tests use temporary directories to avoid side effects
- Python script tests use mock processes to avoid external dependencies
