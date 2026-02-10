# Requirements Document: AI Forge Workflow Application

## Introduction

AI Forge is a macOS SwiftUI application that guides users through a comprehensive fine-tuning workflow for AI models. The application transforms an existing Swift-specific fine-tuning workflow into a domain-agnostic, user-friendly tool that supports project management, step-by-step guidance, and integration with Python-based fine-tuning scripts. The system enables users to create, configure, and manage multiple fine-tuning projects across any knowledge domain while maintaining clear progress tracking and state management.

## Glossary

- **AI_Forge**: The macOS SwiftUI application system
- **Project**: A user-created container for a single fine-tuning workflow instance with associated configuration and state
- **Workflow_Step**: One of six sequential stages in the fine-tuning process
- **Source_Files**: Input files (API documentation and code examples) used to generate training data
- **Training_Dataset**: Optimized data generated from source files for model fine-tuning
- **Fine_Tuning_Configuration**: Settings that control model training parameters
- **Project_Manager**: Component responsible for creating, saving, and loading projects
- **Workflow_Engine**: Component that manages workflow step progression and validation
- **File_System_Manager**: Component that handles directory structure and file operations per project
- **Python_Script_Executor**: Component that invokes Python scripts for dataset generation and fine-tuning
- **Project_State**: Current progress and status information for a project

## Requirements

### Requirement 1: Project Management

**User Story:** As a user, I want to create and manage multiple fine-tuning projects, so that I can work on different AI models for different knowledge domains simultaneously.

#### Acceptance Criteria

1. WHEN a user creates a new project, THE AI_Forge SHALL prompt for a project name and create a new Project with initial state
2. WHEN a user provides a project name, THE AI_Forge SHALL validate that the name is non-empty and contains only valid filesystem characters
3. WHEN a project is created, THE AI_Forge SHALL initialize a dedicated directory structure for that project
4. WHEN a user opens the application, THE AI_Forge SHALL display a list of all existing projects
5. WHEN a user selects a project from the list, THE AI_Forge SHALL load that project's state and display its current workflow step
6. WHEN a user saves a project, THE AI_Forge SHALL persist all project data including name, configuration, and current workflow state to disk
7. WHEN a user deletes a project, THE AI_Forge SHALL remove the project from the list and optionally delete associated files

### Requirement 2: Domain-Agnostic Workflow Configuration

**User Story:** As a user, I want to configure the fine-tuning workflow for any knowledge domain, so that I can use the application beyond just Swift programming.

#### Acceptance Criteria

1. WHEN a user creates a new project, THE AI_Forge SHALL allow specification of the target knowledge domain as a text field
2. WHEN a user configures a project, THE AI_Forge SHALL store domain-specific information including domain name and description
3. WHEN displaying workflow steps, THE AI_Forge SHALL use domain-agnostic terminology that applies to any knowledge area
4. WHEN a user configures source file locations, THE AI_Forge SHALL allow custom directory paths rather than hardcoded Swift-specific paths
5. WHERE a workflow step references domain-specific concepts, THE AI_Forge SHALL use configurable labels and descriptions

### Requirement 3: Workflow Step Guidance

**User Story:** As a user, I want clear step-by-step guidance through the fine-tuning workflow, so that I understand what to do at each stage.

#### Acceptance Criteria

1. THE AI_Forge SHALL display all six workflow steps in sequential order: Prepare Source Files, Generate Optimized Dataset, Configure Fine-Tuning, Run Fine-Tuning, Evaluate for Overfitting, Convert and Deploy
2. WHEN displaying a workflow step, THE AI_Forge SHALL show the step title, description, and required actions
3. WHEN a user views a workflow step, THE AI_Forge SHALL indicate whether the step is pending, in progress, completed, or failed
4. WHEN a user completes a workflow step, THE AI_Forge SHALL mark that step as completed and enable the next step
5. WHEN a workflow step has prerequisites, THE AI_Forge SHALL prevent progression until prerequisites are satisfied
6. WHEN a user navigates between steps, THE AI_Forge SHALL preserve the state of each step

### Requirement 4: Source File Management

**User Story:** As a user, I want to manage source files for training data generation, so that I can organize my input materials effectively.

#### Acceptance Criteria

1. WHEN a user is on the Prepare Source Files step, THE AI_Forge SHALL display designated directories for API documentation and code examples
2. WHEN a user adds source files, THE File_System_Manager SHALL copy or reference files in the project's source directory structure
3. WHEN source files are added, THE AI_Forge SHALL validate that files exist and are readable
4. WHEN a user views source files, THE AI_Forge SHALL display a list of all files in each category with file names and sizes
5. WHEN a user removes a source file, THE AI_Forge SHALL update the file list and optionally delete the file from the project directory
6. WHEN the Prepare Source Files step is marked complete, THE AI_Forge SHALL verify that at least one source file exists in the required directories

### Requirement 5: Dataset Generation Integration

**User Story:** As a user, I want to generate optimized training datasets from my source files, so that I can prepare data for fine-tuning.

#### Acceptance Criteria

1. WHEN a user initiates dataset generation, THE Python_Script_Executor SHALL invoke the dataset generation Python script with appropriate parameters
2. WHEN the dataset generation script runs, THE AI_Forge SHALL display real-time output from the script execution
3. WHEN the dataset generation script completes successfully, THE AI_Forge SHALL mark the Generate Optimized Dataset step as completed
4. IF the dataset generation script fails, THEN THE AI_Forge SHALL display error messages and mark the step as failed
5. WHEN dataset generation completes, THE AI_Forge SHALL validate that output files were created in the expected location
6. WHEN a user views the Generate Optimized Dataset step, THE AI_Forge SHALL display the path to the generated dataset files

### Requirement 6: Fine-Tuning Configuration

**User Story:** As a user, I want to configure fine-tuning parameters, so that I can control how my model is trained.

#### Acceptance Criteria

1. WHEN a user is on the Configure Fine-Tuning step, THE AI_Forge SHALL display editable fields for all fine-tuning parameters
2. THE AI_Forge SHALL provide configuration fields for model name, learning rate, batch size, number of epochs, and output directory
3. WHEN a user modifies configuration values, THE AI_Forge SHALL validate that values are within acceptable ranges
4. WHEN a user saves configuration, THE Fine_Tuning_Configuration SHALL persist settings to a configuration file in the project directory
5. WHEN a user loads a project, THE AI_Forge SHALL read and display previously saved configuration values
6. WHEN configuration is saved, THE AI_Forge SHALL mark the Configure Fine-Tuning step as completed

### Requirement 7: Fine-Tuning Execution

**User Story:** As a user, I want to execute the fine-tuning process, so that I can train my AI model.

#### Acceptance Criteria

1. WHEN a user initiates fine-tuning, THE Python_Script_Executor SHALL invoke the fine-tuning Python script with configuration parameters
2. WHEN the fine-tuning script runs, THE AI_Forge SHALL display real-time progress including current epoch and loss metrics
3. WHEN fine-tuning is in progress, THE AI_Forge SHALL provide a cancel button to terminate the process
4. WHEN fine-tuning completes successfully, THE AI_Forge SHALL mark the Run Fine-Tuning step as completed
5. IF fine-tuning fails, THEN THE AI_Forge SHALL display error messages and mark the step as failed
6. WHEN fine-tuning completes, THE AI_Forge SHALL validate that model checkpoint files were created

### Requirement 8: Model Evaluation

**User Story:** As a user, I want to evaluate my fine-tuned model for overfitting, so that I can assess model quality.

#### Acceptance Criteria

1. WHEN a user initiates evaluation, THE Python_Script_Executor SHALL invoke the evaluation Python script with test data
2. WHEN evaluation runs, THE AI_Forge SHALL display evaluation metrics including test loss and accuracy
3. WHEN evaluation completes successfully, THE AI_Forge SHALL mark the Evaluate for Overfitting step as completed
4. IF evaluation fails, THEN THE AI_Forge SHALL display error messages and mark the step as failed
5. WHEN evaluation completes, THE AI_Forge SHALL display recommendations based on evaluation results
6. WHEN a user views evaluation results, THE AI_Forge SHALL show comparison between training and test metrics

### Requirement 9: Model Conversion and Deployment

**User Story:** As a user, I want to convert and deploy my fine-tuned model, so that I can use it for inference.

#### Acceptance Criteria

1. WHEN a user initiates model conversion, THE Python_Script_Executor SHALL invoke the conversion script with model checkpoint path
2. WHEN conversion runs, THE AI_Forge SHALL display conversion progress and output format information
3. WHEN conversion completes successfully, THE AI_Forge SHALL mark the Convert and Deploy step as completed
4. IF conversion fails, THEN THE AI_Forge SHALL display error messages and mark the step as failed
5. WHEN conversion completes, THE AI_Forge SHALL display the path to the converted model file
6. WHEN a user views the Convert and Deploy step, THE AI_Forge SHALL provide options to export or copy the model to a deployment location

### Requirement 10: Project State Persistence

**User Story:** As a user, I want my project progress to be automatically saved, so that I can resume work without losing progress.

#### Acceptance Criteria

1. WHEN a user completes a workflow step, THE AI_Forge SHALL automatically save the project state to disk
2. WHEN a user modifies project configuration, THE AI_Forge SHALL automatically save changes within 5 seconds
3. WHEN a user closes the application, THE AI_Forge SHALL ensure all project data is persisted before termination
4. WHEN a user reopens a project, THE AI_Forge SHALL restore the exact state including current step and all configuration
5. WHEN project state is saved, THE AI_Forge SHALL use a reliable serialization format that preserves all data
6. IF a save operation fails, THEN THE AI_Forge SHALL notify the user and attempt to retry

### Requirement 11: File System Organization

**User Story:** As a system administrator, I want projects to have a consistent directory structure, so that files are organized and predictable.

#### Acceptance Criteria

1. WHEN a project is created, THE File_System_Manager SHALL create a root directory named after the project
2. THE File_System_Manager SHALL create subdirectories for source files, generated datasets, model checkpoints, and configuration files
3. WHEN files are generated by workflow steps, THE File_System_Manager SHALL place them in the appropriate subdirectory
4. WHEN a user queries file locations, THE AI_Forge SHALL provide absolute paths to all project directories
5. WHEN a project is deleted, THE File_System_Manager SHALL optionally remove all project directories and files
6. THE File_System_Manager SHALL ensure directory paths are valid for macOS filesystem conventions

### Requirement 12: Python Script Integration

**User Story:** As a developer, I want the application to integrate seamlessly with Python scripts, so that existing workflow tools continue to work.

#### Acceptance Criteria

1. WHEN the application starts, THE Python_Script_Executor SHALL verify that Python is installed and accessible
2. WHEN a Python script is invoked, THE Python_Script_Executor SHALL pass all required command-line arguments
3. WHEN a Python script executes, THE Python_Script_Executor SHALL capture stdout and stderr streams
4. WHEN a Python script completes, THE Python_Script_Executor SHALL return the exit code to determine success or failure
5. IF a Python script is not found, THEN THE AI_Forge SHALL display an error message with the expected script location
6. WHEN a Python script runs, THE Python_Script_Executor SHALL set the working directory to the project root

### Requirement 13: User Interface Navigation

**User Story:** As a user, I want intuitive navigation through the application, so that I can easily access all features.

#### Acceptance Criteria

1. THE AI_Forge SHALL display a main window with a project list sidebar and workflow detail view
2. WHEN a user selects a project, THE AI_Forge SHALL display that project's workflow steps in the detail view
3. WHEN a user clicks on a workflow step, THE AI_Forge SHALL display detailed information and actions for that step
4. THE AI_Forge SHALL provide navigation buttons to move between workflow steps sequentially
5. THE AI_Forge SHALL provide a menu bar with options for creating, opening, and deleting projects
6. WHEN a user performs an action, THE AI_Forge SHALL provide visual feedback indicating the action is in progress

### Requirement 14: Error Handling and Validation

**User Story:** As a user, I want clear error messages when something goes wrong, so that I can understand and fix issues.

#### Acceptance Criteria

1. WHEN an error occurs during any workflow step, THE AI_Forge SHALL display a user-friendly error message
2. WHEN a Python script fails, THE AI_Forge SHALL display the script's error output
3. WHEN file operations fail, THE AI_Forge SHALL display the specific file path and error reason
4. WHEN validation fails, THE AI_Forge SHALL highlight the invalid field and explain the validation rule
5. IF a critical error occurs, THEN THE AI_Forge SHALL log detailed error information for debugging
6. WHEN an error is displayed, THE AI_Forge SHALL provide actionable suggestions for resolution

### Requirement 15: Progress Tracking and Status Display

**User Story:** As a user, I want to see my progress through the workflow, so that I know what I've completed and what remains.

#### Acceptance Criteria

1. THE AI_Forge SHALL display a visual progress indicator showing completed, current, and pending workflow steps
2. WHEN a workflow step is in progress, THE AI_Forge SHALL display a progress bar or spinner
3. WHEN all workflow steps are completed, THE AI_Forge SHALL display a completion message
4. WHEN a user views the project list, THE AI_Forge SHALL show each project's current workflow step
5. WHEN a workflow step fails, THE AI_Forge SHALL display a failure indicator with the option to retry
6. THE AI_Forge SHALL display timestamps for when each workflow step was completed
