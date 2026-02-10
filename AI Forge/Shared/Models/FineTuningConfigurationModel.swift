// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

enum ConfigurationError: Error, LocalizedError {
    case emptyModelName
    case invalidLearningRate
    case invalidBatchSize
    case invalidEpochs
    
    var errorDescription: String? {
        switch self {
        case .emptyModelName: return "Model name cannot be empty"
        case .invalidLearningRate: return "Learning rate must be greater than 0"
        case .invalidBatchSize: return "Batch size must be greater than 0"
        case .invalidEpochs: return "Number of epochs must be greater than 0"
        }
    }
}

@Model
final class FineTuningConfigurationModel {
    var modelName: String
    var learningRate: Double
    var batchSize: Int
    var numberOfEpochs: Int
    var outputDirectory: String
    var datasetPath: String
    var additionalParameters: [String: String]
    
    init() {
        self.modelName = ""
        self.learningRate = 0.0001
        self.batchSize = 8
        self.numberOfEpochs = 3
        self.outputDirectory = ""
        self.datasetPath = ""
        self.additionalParameters = [:]
    }
}

// MARK: - Validation
extension FineTuningConfigurationModel {
    var isValid: Bool {
        return modelName.isEmpty == false &&
               learningRate > 0 &&
               batchSize > 0 &&
               numberOfEpochs > 0
    }
    
    func validate() throws {
        guard modelName.isEmpty == false else {
            throw ConfigurationError.emptyModelName
        }
        guard learningRate > 0 else {
            throw ConfigurationError.invalidLearningRate
        }
        guard batchSize > 0 else {
            throw ConfigurationError.invalidBatchSize
        }
        guard numberOfEpochs > 0 else {
            throw ConfigurationError.invalidEpochs
        }
    }
}

// MARK: - Preview Helpers
extension FineTuningConfigurationModel {
    static let mock: FineTuningConfigurationModel = {
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        return config
    }()
}
