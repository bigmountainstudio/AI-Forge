// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

@Observable
final class WorkflowEngineObservable {
    private let modelContext: ModelContext
    private let pythonExecutor: PythonScriptExecutor
    private let fileSystemManager: FileSystemManager
    
    var currentProject: ProjectModel?
    var currentStep: WorkflowStepModel?
    var isExecutingStep = false
    var executionOutput: String = ""
    
    init(modelContext: ModelContext,
         pythonExecutor: PythonScriptExecutor,
         fileSystemManager: FileSystemManager) {
        self.modelContext = modelContext
        self.pythonExecutor = pythonExecutor
        self.fileSystemManager = fileSystemManager
    }
    
    func loadProject(_ project: ProjectModel) {
        currentProject = project
        if project.currentStepIndex < project.workflowSteps.count {
            currentStep = project.workflowSteps[project.currentStepIndex]
        }
    }
    
    func canProgressToNextStep() -> Bool {
        guard let project = currentProject else { return false }
        guard let step = currentStep else { return false }
        
        // Can only progress if current step is completed
        return step.status == .completed && project.currentStepIndex < project.workflowSteps.count - 1
    }
    
    func progressToNextStep() throws {
        guard let project = currentProject else { return }
        guard canProgressToNextStep() else {
            throw WorkflowError.cannotProgress
        }
        
        project.currentStepIndex += 1
        currentStep = project.workflowSteps[project.currentStepIndex]
        
        try modelContext.save()
    }
    
    func markStepComplete(_ step: WorkflowStepModel) throws {
        step.status = .completed
        step.completedAt = Date()
        step.errorMessage = nil
        
        try modelContext.save()
    }
    
    func markStepFailed(_ step: WorkflowStepModel, error: String) throws {
        step.status = .failed
        step.errorMessage = error
        
        try modelContext.save()
    }
    
    func retryStep(_ step: WorkflowStepModel) throws {
        step.status = .pending
        step.errorMessage = nil
        
        try modelContext.save()
    }
}

enum WorkflowError: Error, LocalizedError {
    case cannotProgress
    case stepExecutionFailed
    case invalidState
    
    var errorDescription: String? {
        switch self {
        case .cannotProgress: return "Cannot progress to next step"
        case .stepExecutionFailed: return "Step execution failed"
        case .invalidState: return "Invalid workflow state"
        }
    }
}
