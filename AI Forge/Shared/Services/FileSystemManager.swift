// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

final class FileSystemManager {
    private let fileManager = FileManager.default
    private let baseProjectsDirectory: URL
    
    init() {
        // Initialize base projects directory in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseProjectsDirectory = appSupport.appendingPathComponent("AIForge/Projects")
        
        // Create base directory if it doesn't exist
        try? fileManager.createDirectory(at: baseProjectsDirectory, withIntermediateDirectories: true)
    }
    
    func createProjectDirectory(projectName: String) throws -> URL {
        let projectURL = baseProjectsDirectory.appendingPathComponent(projectName)
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try createProjectSubdirectories(projectRoot: projectURL)
        return projectURL
    }
    
    func createProjectSubdirectories(projectRoot: URL) throws {
        let subdirectories = ["source", "datasets", "models", "config", "logs"]
        for subdirectory in subdirectories {
            let subdirURL = projectRoot.appendingPathComponent(subdirectory)
            try fileManager.createDirectory(at: subdirURL, withIntermediateDirectories: true)
        }
    }
    
    func deleteProjectDirectory(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    func getProjectDirectory(projectName: String) -> URL {
        return baseProjectsDirectory.appendingPathComponent(projectName)
    }
}
