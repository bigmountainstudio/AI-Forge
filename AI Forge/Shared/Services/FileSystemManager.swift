// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

final class FileSystemManager {
    private let fileManager: FileManager
    private let baseProjectsDirectory: URL
    
    init() {
        self.fileManager = FileManager.default
        
        // Initialize base projects directory in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseProjectsDirectory = appSupport.appendingPathComponent("AIForge/Projects", isDirectory: true)
        
        // Create base directory if it doesn't exist
        try? fileManager.createDirectory(at: baseProjectsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Project Directory Management
    
    /// Creates a project directory with all required subdirectories
    /// - Parameter projectName: The name of the project
    /// - Returns: URL of the created project directory
    /// - Throws: Error if directory creation fails
    func createProjectDirectory(projectName: String) throws -> URL {
        let projectURL = baseProjectsDirectory.appendingPathComponent(projectName, isDirectory: true)
        
        // Create root project directory
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        
        // Create subdirectories
        try createProjectSubdirectories(projectRoot: projectURL)
        
        return projectURL
    }
    
    /// Creates standard subdirectories within a project root
    /// - Parameter projectRoot: The root URL of the project
    /// - Throws: Error if subdirectory creation fails
    func createProjectSubdirectories(projectRoot: URL) throws {
        let subdirectories = ["source", "datasets", "models", "config", "logs"]
        
        for subdirectory in subdirectories {
            let subdirURL = projectRoot.appendingPathComponent(subdirectory, isDirectory: true)
            try fileManager.createDirectory(at: subdirURL, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the project directory URL for a given project name
    /// - Parameter projectName: The name of the project
    /// - Returns: URL of the project directory
    func getProjectDirectory(projectName: String) -> URL {
        return baseProjectsDirectory.appendingPathComponent(projectName, isDirectory: true)
    }
    
    /// Deletes an entire project directory
    /// - Parameter projectURL: The URL of the project directory to delete
    /// - Throws: Error if deletion fails
    func deleteProjectDirectory(at projectURL: URL) throws {
        try fileManager.removeItem(at: projectURL)
    }
    
    // MARK: - Source File Management
    
    /// Adds a source file to the project by copying it to the appropriate category directory
    /// - Parameters:
    ///   - sourceURL: The URL of the file to add
    ///   - projectURL: The project directory URL
    ///   - category: The category of the source file
    /// - Returns: SourceFileReference for the added file
    /// - Throws: Error if file operations fail
    func addSourceFile(at sourceURL: URL, to projectURL: URL, category: SourceFileCategory) throws -> SourceFileReference {
        // Validate source file exists
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileSystemError.fileNotFound(sourceURL.path)
        }
        
        // Determine destination directory based on category
        let categorySubdir = category == .apiDocumentation ? "api_docs" : "code_examples"
        let sourceDir = projectURL.appendingPathComponent("source/\(categorySubdir)", isDirectory: true)
        
        // Create category directory if it doesn't exist
        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        
        // Copy file to destination
        let fileName = sourceURL.lastPathComponent
        let destinationURL = sourceDir.appendingPathComponent(fileName)
        
        // If file already exists, remove it first
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Create and return SourceFileReference
        return SourceFileReference(
            fileName: fileName,
            filePath: destinationURL.path,
            fileSize: fileSize,
            category: category
        )
    }
    
    /// Removes a source file from the project
    /// - Parameter fileReference: The SourceFileReference to remove
    /// - Throws: Error if deletion fails
    func removeSourceFile(_ fileReference: SourceFileReference) throws {
        let fileURL = URL(fileURLWithPath: fileReference.filePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileSystemError.fileNotFound(fileURL.path)
        }
        
        try fileManager.removeItem(at: fileURL)
    }
    
    /// Lists all source files in a project directory, optionally filtered by category
    /// - Parameters:
    ///   - projectURL: The project directory URL
    ///   - category: Optional category filter
    /// - Returns: Array of SourceFileReference objects
    /// - Throws: Error if directory reading fails
    func listSourceFiles(in projectURL: URL, category: SourceFileCategory? = nil) throws -> [SourceFileReference] {
        var sourceFiles: [SourceFileReference] = []
        
        let sourceDir = projectURL.appendingPathComponent("source", isDirectory: true)
        
        // Determine which subdirectories to scan
        let subdirs: [(String, SourceFileCategory)]
        if let category = category {
            let subdir = category == .apiDocumentation ? "api_docs" : "code_examples"
            subdirs = [(subdir, category)]
        } else {
            subdirs = [("api_docs", .apiDocumentation), ("code_examples", .codeExamples)]
        }
        
        // Scan each subdirectory
        for (subdir, cat) in subdirs {
            let categoryDir = sourceDir.appendingPathComponent(subdir, isDirectory: true)
            
            guard fileManager.fileExists(atPath: categoryDir.path) else {
                continue
            }
            
            let contents = try fileManager.contentsOfDirectory(at: categoryDir, includingPropertiesForKeys: [.fileSizeKey])
            
            for fileURL in contents where fileURL.hasDirectoryPath == false {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                let reference = SourceFileReference(
                    fileName: fileURL.lastPathComponent,
                    filePath: fileURL.path,
                    fileSize: fileSize,
                    category: cat
                )
                
                sourceFiles.append(reference)
            }
        }
        
        return sourceFiles
    }
    
    // MARK: - Folder Scanning
    
    /// Recursively discovers all .swift files in a directory and its subdirectories
    /// - Parameter directory: The directory URL to scan
    /// - Returns: Array of URLs pointing to .swift files found
    /// - Throws: FileSystemError if the directory cannot be accessed or enumerated
    func findSwiftFiles(in directory: URL) throws -> [URL] {
        var swiftFiles: [URL] = []
        
        // Verify directory exists and is accessible
        guard fileManager.fileExists(atPath: directory.path) else {
            throw FileSystemError.directoryNotFound(directory.path)
        }
        
        // Check if path is actually a directory
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            throw FileSystemError.notADirectory(directory.path)
        }
        
        // Create enumerator to recursively scan directory
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw FileSystemError.cannotEnumerateDirectory(directory.path)
        }
        
        // Iterate through all files in directory and subdirectories
        for case let fileURL as URL in enumerator {
            do {
                // Get file properties
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                
                // Check if it's a regular file (not a directory)
                if resourceValues.isRegularFile == true && fileURL.pathExtension == "swift" {
                    swiftFiles.append(fileURL)
                }
            } catch {
                // Skip files that cannot be accessed
                continue
            }
        }
        
        return swiftFiles
    }
    
    // MARK: - Validation
    
    /// Validates that a file path exists and is accessible
    /// - Parameter path: The file path to validate
    /// - Returns: True if the file exists and is accessible
    func validateFilePath(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
}

// MARK: - Errors

enum FileSystemError: Error, LocalizedError {
    case fileNotFound(String)
    case directoryCreationFailed(String)
    case fileCopyFailed(String)
    case directoryNotFound(String)
    case notADirectory(String)
    case cannotEnumerateDirectory(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory at path: \(path)"
        case .fileCopyFailed(let path):
            return "Failed to copy file to path: \(path)"
        case .directoryNotFound(let path):
            return "Directory not found at path: \(path)"
        case .notADirectory(let path):
            return "Path is not a directory: \(path)"
        case .cannotEnumerateDirectory(let path):
            return "Cannot access or enumerate directory at path: \(path)"
        }
    }
}
