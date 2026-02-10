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
        // Validate project name
        let validationResult = validateProjectName(name)
        guard validationResult.isValid else {
            throw ProjectError.invalidName(validationResult.message)
        }
        
        // Create project directory
        let projectDirectory = try fileSystemManager.createProjectDirectory(projectName: name)
        
        // Create project model
        let project = ProjectModel(name: name, domainName: domainName, domainDescription: domainDescription)
        project.projectDirectoryPath = projectDirectory.path
        
        // Insert into context
        modelContext.insert(project)
        
        // Save context
        try modelContext.save()
        
        return project
    }
    
    func loadProjects() async {
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
    
    func deleteProject(_ project: ProjectModel) async throws {
        // Optionally delete project directory
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        try? fileSystemManager.deleteProjectDirectory(at: projectURL)
        
        // Delete from context
        modelContext.delete(project)
        
        // Save context
        try modelContext.save()
        
        // Reload projects
        await loadProjects()
    }
    
    func saveProject(_ project: ProjectModel) throws {
        project.updatedAt = Date()
        try modelContext.save()
    }
    
    func validateProjectName(_ name: String) -> ValidationResult {
        // Check for empty name
        guard name.isEmpty == false else {
            return ValidationResult(isValid: false, message: "Project name cannot be empty")
        }
        
        // Check for invalid filesystem characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        guard name.rangeOfCharacter(from: invalidCharacters) == nil else {
            return ValidationResult(isValid: false, message: "Project name contains invalid characters")
        }
        
        return ValidationResult(isValid: true, message: "")
    }
}

struct ValidationResult {
    let isValid: Bool
    let message: String
}

enum ProjectError: Error, LocalizedError {
    case invalidName(String)
    case directoryCreationFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidName(let message): return message
        case .directoryCreationFailed: return "Failed to create project directory"
        case .saveFailed: return "Failed to save project"
        }
    }
}
