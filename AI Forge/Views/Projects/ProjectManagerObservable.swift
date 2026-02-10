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
        do {
            // Validate project name
            let validationResult = validateProjectName(name)
            guard validationResult.isValid else {
                let error = ProjectError.invalidName(validationResult.message)
                errorMessage = "Project creation failed: \(error.localizedDescription)"
                ErrorLogger.log("Project name validation failed: \(validationResult.message)", severity: .warning, category: .project)
                throw error
            }
            
            // Create project directory
            let projectDirectory: URL
            do {
                projectDirectory = try fileSystemManager.createProjectDirectory(projectName: name)
            } catch {
                let wrappedError = ProjectError.directoryCreationFailed
                errorMessage = "Failed to create project directory for '\(name)': \(error.localizedDescription)"
                ErrorLogger.logError(error, message: "Failed to create project directory for '\(name)'", category: .fileSystem)
                throw wrappedError
            }
            
            // Create project model
            let project = ProjectModel(name: name, domainName: domainName, domainDescription: domainDescription)
            project.projectDirectoryPath = projectDirectory.path
            
            // Insert into context
            modelContext.insert(project)
            
            // Save context
            do {
                try modelContext.save()
            } catch {
                let wrappedError = ProjectError.saveFailed
                errorMessage = "Failed to save project '\(name)' to database: \(error.localizedDescription)"
                ErrorLogger.logCritical(error, message: "Failed to save project '\(name)' to database", category: .database)
                throw wrappedError
            }
            
            // Clear any previous error messages on success
            errorMessage = nil
            ErrorLogger.log("Successfully created project '\(name)'", severity: .info, category: .project)
            
            return project
        } catch {
            // Ensure error message is set if not already
            if errorMessage == nil {
                errorMessage = "Unexpected error creating project: \(error.localizedDescription)"
                ErrorLogger.logCritical(error, message: "Unexpected error creating project '\(name)'", category: .project)
            }
            throw error
        }
    }
    
    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        
        let descriptor = FetchDescriptor<ProjectModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            projects = try modelContext.fetch(descriptor)
            errorMessage = nil // Clear error on success
        } catch {
            errorMessage = "Failed to load projects from database: \(error.localizedDescription)"
            projects = [] // Clear projects list on error
            ErrorLogger.logError(error, message: "Failed to load projects from database", category: .database)
        }
    }
    
    func deleteProject(_ project: ProjectModel) async throws {
        do {
            // Optionally delete project directory
            let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
            do {
                try fileSystemManager.deleteProjectDirectory(at: projectURL)
            } catch {
                // Log but don't fail if directory deletion fails
                errorMessage = "Warning: Failed to delete project directory at '\(projectURL.path)': \(error.localizedDescription)"
                ErrorLogger.logError(error, message: "Failed to delete project directory at '\(projectURL.path)'", category: .fileSystem)
            }
            
            // Delete from context
            modelContext.delete(project)
            
            // Save context
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to delete project '\(project.name)' from database: \(error.localizedDescription)"
                ErrorLogger.logCritical(error, message: "Failed to delete project '\(project.name)' from database", category: .database)
                throw error
            }
            
            // Reload projects
            await loadProjects()
            
            // Clear error message on success
            errorMessage = nil
            ErrorLogger.log("Successfully deleted project '\(project.name)'", severity: .info, category: .project)
        } catch {
            if errorMessage == nil {
                errorMessage = "Unexpected error deleting project '\(project.name)': \(error.localizedDescription)"
                ErrorLogger.logCritical(error, message: "Unexpected error deleting project '\(project.name)'", category: .project)
            }
            throw error
        }
    }
    
    func saveProject(_ project: ProjectModel) throws {
        do {
            project.updatedAt = Date()
            try modelContext.save()
            errorMessage = nil // Clear error on success
        } catch {
            let wrappedError = ProjectError.saveFailed
            errorMessage = "Failed to save changes to project '\(project.name)': \(error.localizedDescription)"
            ErrorLogger.logCritical(error, message: "Failed to save changes to project '\(project.name)'", category: .database)
            throw wrappedError
        }
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
