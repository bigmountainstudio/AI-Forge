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
        var addedCount = 0
        
        for url in urls {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let reference = try fileSystemManager.addSourceFile(
                    at: url,
                    to: projectURL,
                    category: .apiDocumentation
                )
                sourceFiles.append(reference)
                addedCount += 1
            } catch {
                errorMessage = "Failed to add file '\(url.lastPathComponent)': \(error.localizedDescription)"
                // Continue with other files even if one fails
            }
        }
        
        // Clear error if at least some files were added successfully
        if addedCount > 0 {
            errorMessage = nil
            // Reload to ensure UI is in sync with file system
            await loadSourceFiles()
        }
    }
    
    func addSourceFilesOrFolders(_ urls: [URL], category: SourceFileCategory) async {
        guard let project = currentProject else {
            errorMessage = "Cannot add source files: No project is currently loaded"
            return
        }
        
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        var addedCount = 0
        var failedItems: [(name: String, reason: String)] = []
        
        for url in urls {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Validate the file or folder first
            let validationResult = fileSystemManager.validateFileOrFolder(url)
            
            guard validationResult.isValid else {
                failedItems.append((name: validationResult.fileName, reason: validationResult.errorMessage ?? "Unknown error"))
                continue
            }
            
            do {
                // Detect whether URL is a file or folder
                var isDir: ObjCBool = false
                let fileManager = FileManager.default
                
                guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else {
                    failedItems.append((name: url.lastPathComponent, reason: "File or folder not found"))
                    continue
                }
                
                if isDir.boolValue {
                    // Process folder recursively
                    let swiftFiles = try fileSystemManager.findSwiftFiles(in: url)
                    
                    if swiftFiles.isEmpty {
                        failedItems.append((name: url.lastPathComponent, reason: "No .swift files found in folder or its subdirectories"))
                        continue
                    }
                    
                    for swiftFile in swiftFiles {
                        do {
                            let reference = try fileSystemManager.addSourceFile(
                                at: swiftFile,
                                to: projectURL,
                                category: category
                            )
                            sourceFiles.append(reference)
                            addedCount += 1
                        } catch {
                            failedItems.append((name: swiftFile.lastPathComponent, reason: error.localizedDescription))
                        }
                    }
                } else {
                    // Process individual file
                    let reference = try fileSystemManager.addSourceFile(
                        at: url,
                        to: projectURL,
                        category: category
                    )
                    sourceFiles.append(reference)
                    addedCount += 1
                }
            } catch {
                failedItems.append((name: url.lastPathComponent, reason: error.localizedDescription))
            }
        }
        
        // Update error message based on results
        if addedCount > 0 {
            errorMessage = nil
            // Reload to ensure UI is in sync with file system
            await loadSourceFiles()
        }
        
        if failedItems.isEmpty == false {
            let failureDetails = failedItems.map { "\(String($0.name)): \($0.reason)" }.joined(separator: "\n• ")
            errorMessage = "Failed to add \(failedItems.count) item(s):\n• \(failureDetails)"
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
        
        // Requirement 6.1, 6.2: Validate step completion before execution
        // For step 1 (Prepare Source Files), validate that files exist
        if step.stepNumber == 1 {
            let (isValid, validationError) = validateStepCompletion()
            if isValid == false {
                errorMessage = validationError
                ErrorLogger.log("Step completion validation failed: \(validationError ?? "Unknown error")", severity: .warning, category: .workflow)
                return
            }
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
                    // Requirement 6.5: Record which categories contain files
                    let categoriesWithFiles = getCategoriesWithFiles()
                    
                    try workflowEngine.markStepComplete(step)
                    errorMessage = nil
                    ErrorLogger.log("Successfully completed step '\(step.title)' for project '\(project.name)'. Categories with files: \(categoriesWithFiles.map { $0.rawValue }.joined(separator: ", "))", severity: .info, category: .workflow)
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
    
    // MARK: - Step Completion Validation
    
    /// Validates that the Prepare Source Files step can be completed
    /// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
    func validateStepCompletion() -> (isValid: Bool, errorMessage: String?) {
        // Requirement 6.1: Verify at least one file exists before allowing step completion
        let totalFiles = sourceFiles.count
        
        if totalFiles == 0 {
            // Requirement 6.2: Display validation error if no files exist
            return (isValid: false, errorMessage: "At least one source file is required. Please add API documentation files or code examples to proceed.")
        }
        
        return (isValid: true, errorMessage: nil)
    }
    
    /// Gets the categories that contain files
    /// Requirement 6.5: Record which categories contain files
    func getCategoriesWithFiles() -> [SourceFileCategory] {
        var categories: [SourceFileCategory] = []
        
        if sourceFiles.contains(where: { $0.category == .apiDocumentation }) {
            categories.append(.apiDocumentation)
        }
        
        if sourceFiles.contains(where: { $0.category == .codeExamples }) {
            categories.append(.codeExamples)
        }
        
        return categories
    }
    
    /// Checks if a specific category has files
    func hasCategoryFiles(_ category: SourceFileCategory) -> Bool {
        return sourceFiles.contains { $0.category == category }
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
        let scriptName: String
        
        switch stepNumber {
        case 1: scriptName = "copy_code_examples.py"
        case 2: scriptName = "generate_unified_dataset.py"
        case 4: scriptName = "generate_optimized_dataset.py"
        case 5: scriptName = "evaluate_overfitting.sh"
        case 6: scriptName = "convert_to_ollama.sh"
        default: return ""
        }
        
        // Scripts are in Resources root, not in a scripts subfolder
        if let scriptPath = Bundle.main.path(forResource: scriptName, ofType: nil) {
            return scriptPath
        }
        
        // Development fallback
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            let devPath = resourceURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("AI Forge")
                .appendingPathComponent("Supporting Files")
                .appendingPathComponent("scripts")
                .appendingPathComponent(scriptName)
                .path
            
            if FileManager.default.fileExists(atPath: devPath) {
                return devPath
            }
        }
        
        // Return fallback path
        return "\(Bundle.main.resourcePath ?? "/Applications/AI Forge.app/Contents/Resources")/\(scriptName)"
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
