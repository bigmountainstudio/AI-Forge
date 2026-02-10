// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

final class ValidationHelpers {
    
    // MARK: - Project Name Validation
    
    /// Validates a project name for filesystem compatibility
    /// - Parameter name: The project name to validate
    /// - Returns: True if the name is valid, false otherwise
    static func isValidProjectName(_ name: String) -> Bool {
        // Check for empty name
        guard name.isEmpty == false else {
            return false
        }
        
        // Check for invalid filesystem characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        guard name.rangeOfCharacter(from: invalidCharacters) == nil else {
            return false
        }
        
        return true
    }
    
    // MARK: - File Path Validation
    
    /// Validates that a file path exists and is accessible
    /// - Parameter path: The file path to validate
    /// - Returns: True if the path is valid and accessible, false otherwise
    static func isValidFilePath(_ path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }
    
    // MARK: - Configuration Parameter Validation
    
    /// Validates that a learning rate is positive
    /// - Parameter learningRate: The learning rate to validate
    /// - Returns: True if the learning rate is greater than 0, false otherwise
    static func isValidLearningRate(_ learningRate: Double) -> Bool {
        return learningRate > 0
    }
    
    /// Validates that a batch size is a positive integer
    /// - Parameter batchSize: The batch size to validate
    /// - Returns: True if the batch size is greater than 0, false otherwise
    static func isValidBatchSize(_ batchSize: Int) -> Bool {
        return batchSize > 0
    }
    
    /// Validates that the number of epochs is a positive integer
    /// - Parameter epochs: The number of epochs to validate
    /// - Returns: True if the epochs value is greater than 0, false otherwise
    static func isValidEpochs(_ epochs: Int) -> Bool {
        return epochs > 0
    }
}
