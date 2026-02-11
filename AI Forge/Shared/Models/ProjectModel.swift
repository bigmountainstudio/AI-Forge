// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

@Model
final class ProjectModel {
    var name: String
    var domainName: String
    var domainDescription: String
    var createdAt: Date
    var updatedAt: Date
    var currentStepIndex: Int
    var projectDirectoryPath: String
    
    @Relationship(deleteRule: .cascade) var workflowSteps: [WorkflowStepModel]
    @Relationship(deleteRule: .cascade) var configuration: FineTuningConfigurationModel?
    
    init(name: String, domainName: String, domainDescription: String) {
        self.name = name
        self.domainName = domainName
        self.domainDescription = domainDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.currentStepIndex = 0
        self.projectDirectoryPath = ""
        self.workflowSteps = WorkflowStepModel.createDefaultSteps()
    }
}

// MARK: - Computed Properties
extension ProjectModel {
    var viewCurrentStepTitle: String {
        guard currentStepIndex < workflowSteps.count else { return "Unknown" }
        return workflowSteps[currentStepIndex].title
    }
    
    var viewProgressPercentage: Double {
        let completedSteps = workflowSteps.filter { $0.status == .completed }.count
        return Double(completedSteps) / Double(workflowSteps.count)
    }
}

// MARK: - Preview Helpers
extension ProjectModel {
    static let mock = ProjectModel(
        name: "Swift API Fine-Tuning",
        domainName: "Swift Programming",
        domainDescription: "Fine-tuning for Swift API documentation"
    )
    
    static let mocks = [
        ProjectModel(name: "Swift API", domainName: "Swift", domainDescription: "Swift API docs"),
        ProjectModel(name: "Python ML", domainName: "Machine Learning", domainDescription: "ML models"),
        ProjectModel(name: "Data Pipeline", domainName: "Data Science", domainDescription: "Data processing")
    ]
    
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: ProjectModel.self, WorkflowStepModel.self, FineTuningConfigurationModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        container.mainContext.insert(mock)
        
        return container
    }
    
    @MainActor
    static var emptyPreview: ModelContainer {
        let container = try! ModelContainer(
            for: ProjectModel.self, WorkflowStepModel.self, FineTuningConfigurationModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        return container
    }
}
