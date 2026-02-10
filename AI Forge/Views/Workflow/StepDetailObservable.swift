// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

@Observable
final class StepDetailObservable {
    private let workflowEngine: WorkflowEngineObservable
    private let fileSystemManager: FileSystemManager
    private let pythonExecutor: PythonScriptExecutor
    
    var currentStep: WorkflowStepModel?
    var currentProject: ProjectModel?
    var sourceFiles: [SourceFileReference] = []
    var configuration: FineTuningConfigurationModel?
    var executionOutput: String = ""
    var isExecuting = false
    var errorMessage: String?
    
    init(workflowEngine: WorkflowEngineObservable,
         fileSystemManager: FileSystemManager,
         pythonExecutor: PythonScriptExecutor) {
        self.workflowEngine = workflowEngine
        self.fileSystemManager = fileSystemManager
        self.pythonExecutor = pythonExecutor
    }
    
    func loadStep(_ step: WorkflowStepModel, project: ProjectModel) async {
        currentStep = step
        currentProject = project
        
        // Load step-specific data
        switch step.stepNumber {
        case 1:
            await loadSourceFiles()
        case 3:
            configuration = project.configuration
        default:
            break
        }
    }
    
    func addSourceFiles(_ urls: [URL]) async {
        guard let project = currentProject else {
            errorMessage = "Cannot add source files: No project is currently loaded"
            return
        }
        
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        
        do {
            for url in urls {
                do {
                    let reference = try fileSystemManager.addSourceFile(
                        at: url,
                        to: projectURL,
                        category: .apiDocumentation
                    )
                    sourceFiles.append(reference)
                } catch {
                    errorMessage = "Failed to add file '\(url.lastPathComponent)': \(error.localizedDescription)"
                    // Continue with other files even if one fails
                }
            }
            
            // Clear error if at least some files were added successfully
            if sourceFiles.isEmpty == false {
                errorMessage = nil
            }
        }
    }
    
    func removeSourceFile(_ reference: SourceFileReference) async {
        do {
            try fileSystemManager.removeSourceFile(reference)
            sourceFiles.removeAll { $0.id == reference.id }
            errorMessage = nil // Clear error on success
        } catch {
            errorMessage = "Failed to remove file '\(reference.fileName)': \(error.localizedDescription). The file may have already been deleted or is inaccessible."
        }
    }
    
    func updateConfiguration(_ config: FineTuningConfigurationModel) async {
        configuration = config
    }
    
    func executeStep() async {
        guard let step = currentStep else {
            errorMessage = "Cannot execute step: No step is currently loaded"
            ErrorLogger.log("Attempted to execute step but no step is loaded", severity: .warning, category: .workflow)
            return
        }
        
        guard let project = currentProject else {
            errorMessage = "Cannot execute step: No project is currently loaded"
            ErrorLogger.log("Attempted to execute step but no project is loaded", severity: .warning, category: .workflow)
            return
        }
        
        isExecuting = true
        executionOutput = ""
        errorMessage = nil
        
        defer { isExecuting = false }
        
        do {
            ErrorLogger.log("Starting execution of step '\(step.title)' for project '\(project.name)'", severity: .info, category: .workflow)
            
            let result = try await executeStepScript(step: step, project: project)
            
            if result.success {
                do {
                    try workflowEngine.markStepComplete(step)
                    errorMessage = nil
                    ErrorLogger.log("Successfully completed step '\(step.title)' for project '\(project.name)'", severity: .info, category: .workflow)
                } catch {
                    errorMessage = "Step completed but failed to save state: \(error.localizedDescription)"
                    ErrorLogger.logError(error, message: "Failed to save completion state for step '\(step.title)'", category: .database)
                }
            } else {
                // Display stderr output for script failures
                let errorOutput = result.error.isEmpty == false ? result.error : "Script failed with exit code \(result.exitCode)"
                
                do {
                    try workflowEngine.markStepFailed(step, error: errorOutput)
                } catch {
                    errorMessage = "Failed to mark step as failed: \(error.localizedDescription)"
                    ErrorLogger.logError(error, message: "Failed to mark step '\(step.title)' as failed", category: .database)
                }
                
                errorMessage = "Script execution failed:\n\(errorOutput)\n\nSuggestion: Check the script path, arguments, and ensure all dependencies are installed."
                ErrorLogger.log("Script execution failed for step '\(step.title)': \(errorOutput)", severity: .error, category: .pythonScript)
            }
        } catch {
            let detailedError = "Execution failed for step '\(step.title)': \(error.localizedDescription)\n\nSuggestion: Verify Python is installed and the script exists at the expected location."
            errorMessage = detailedError
            ErrorLogger.logCritical(error, message: "Critical failure executing step '\(step.title)' for project '\(project.name)'", category: .pythonScript)
            
            do {
                try workflowEngine.markStepFailed(step, error: error.localizedDescription)
            } catch {
                errorMessage = "\(detailedError)\n\nAdditionally, failed to save error state: \(error.localizedDescription)"
                ErrorLogger.logCritical(error, message: "Failed to save error state for step '\(step.title)'", category: .database)
            }
        }
    }
    
    func cancelExecution() async {
        await pythonExecutor.cancelExecution()
        isExecuting = false
    }
    
    private func loadSourceFiles() async {
        guard let project = currentProject else {
            errorMessage = "Cannot load source files: No project is currently loaded"
            ErrorLogger.log("Attempted to load source files but no project is loaded", severity: .warning, category: .fileSystem)
            return
        }
        
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        
        do {
            let apiDocs = try fileSystemManager.listSourceFiles(in: projectURL, category: .apiDocumentation)
            let codeExamples = try fileSystemManager.listSourceFiles(in: projectURL, category: .codeExamples)
            sourceFiles = apiDocs + codeExamples
            errorMessage = nil // Clear error on success
        } catch {
            errorMessage = "Failed to load source files from '\(projectURL.path)': \(error.localizedDescription). The project directory may be missing or inaccessible."
            sourceFiles = [] // Clear list on error
            ErrorLogger.logError(error, message: "Failed to load source files from '\(projectURL.path)'", category: .fileSystem)
        }
    }
    
    private func executeStepScript(step: WorkflowStepModel, project: ProjectModel) async throws -> ScriptExecutionResult {
        let scriptPath = getScriptPath(for: step.stepNumber)
        let arguments = getScriptArguments(for: step.stepNumber, project: project)
        
        return try await pythonExecutor.executeScript(
            scriptPath: scriptPath,
            arguments: arguments,
            workingDirectory: project.projectDirectoryPath
        ) { [weak self] output in
            guard let self = self else { return }
            self.executionOutput += output
        }
    }
    
    private func getScriptPath(for stepNumber: Int) -> String {
        // These would be configured or discovered at runtime
        switch stepNumber {
        case 2: return "/path/to/generate_dataset.py"
        case 4: return "/path/to/fine_tune.py"
        case 5: return "/path/to/evaluate.py"
        case 6: return "/path/to/convert_model.py"
        default: return ""
        }
    }
    
    private func getScriptArguments(for stepNumber: Int, project: ProjectModel) -> [String] {
        // Build arguments based on step and project configuration
        var arguments: [String] = []
        
        if let config = project.configuration {
            arguments.append(contentsOf: [
                "--model", config.modelName,
                "--learning-rate", String(config.learningRate),
                "--batch-size", String(config.batchSize),
                "--epochs", String(config.numberOfEpochs)
            ])
        }
        
        return arguments
    }
}
