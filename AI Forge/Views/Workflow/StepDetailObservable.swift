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
        guard let project = currentProject else { return }
        
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        
        do {
            for url in urls {
                let reference = try fileSystemManager.addSourceFile(
                    at: url,
                    to: projectURL,
                    category: .apiDocumentation
                )
                sourceFiles.append(reference)
            }
        } catch {
            errorMessage = "Failed to add source files: \(error.localizedDescription)"
        }
    }
    
    func removeSourceFile(_ reference: SourceFileReference) async {
        do {
            try fileSystemManager.removeSourceFile(reference)
            sourceFiles.removeAll { $0.id == reference.id }
        } catch {
            errorMessage = "Failed to remove source file: \(error.localizedDescription)"
        }
    }
    
    func updateConfiguration(_ config: FineTuningConfigurationModel) async {
        configuration = config
    }
    
    func executeStep() async {
        guard let step = currentStep,
              let project = currentProject else { return }
        
        isExecuting = true
        executionOutput = ""
        errorMessage = nil
        
        defer { isExecuting = false }
        
        do {
            let result = try await executeStepScript(step: step, project: project)
            
            if result.success {
                try workflowEngine.markStepComplete(step)
            } else {
                try workflowEngine.markStepFailed(step, error: result.error)
                errorMessage = result.error
            }
        } catch {
            errorMessage = "Execution failed: \(error.localizedDescription)"
        }
    }
    
    func cancelExecution() async {
        await pythonExecutor.cancelExecution()
        isExecuting = false
    }
    
    private func loadSourceFiles() async {
        guard let project = currentProject else { return }
        
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        
        do {
            let apiDocs = try fileSystemManager.listSourceFiles(in: projectURL, category: .apiDocumentation)
            let codeExamples = try fileSystemManager.listSourceFiles(in: projectURL, category: .codeExamples)
            sourceFiles = apiDocs + codeExamples
        } catch {
            errorMessage = "Failed to load source files: \(error.localizedDescription)"
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
