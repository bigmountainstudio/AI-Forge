// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

@Observable
final class ProjectManagerObservable {
    private let modelContext: ModelContext
    private let fileSystemManager: FileSystemManager
    
    var projects: [ProjectModel] = []
    var selectedProject: ProjectModel?
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext, fileSystemManager: FileSystemManager) {
        self.modelContext = modelContext
        self.fileSystemManager = fileSystemManager
    }
    
    func createProject(name: String, domainName: String, domainDescription: String) async throws -> ProjectModel {
        // Placeholder implementation - will be completed in Task 6.1
        let project = ProjectModel(name: name, domainName: domainName, domainDescription: domainDescription)
        modelContext.insert(project)
        try modelContext.save()
        return project
    }
    
    func loadProjects() async {
        // Placeholder implementation - will be completed in Task 6.1
        isLoading = true
        defer { isLoading = false }
        
        let descriptor = FetchDescriptor<ProjectModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            projects = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
        }
    }
}
