// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

enum ConfigurationError: Error, LocalizedError {
    case emptyModelName
    case invalidModelFormat
    case invalidLearningRate
    case invalidBatchSize
    case invalidEpochs
    
    var errorDescription: String? {
        switch self {
        case .emptyModelName: return "Model name cannot be empty"
        case .invalidModelFormat: return "Invalid model name format. MLX requires a HuggingFace repo ID (e.g., 'Qwen/Qwen2.5-Coder-7B-Instruct') or a local path. Ollama-style names (with ':') are not supported."
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
    var datasetSize: Int = 0  // Number of training examples
    var useLowMemoryMode: Bool = true  // MLX-specific: memory optimization
    var maxSequenceLength: Int = 256  // MLX-specific: token limit per example
    var loraRank: Int = 8  // MLX-specific: LoRA rank for adaptation
    
    init() {
        self.modelName = ""
        self.learningRate = 5e-5  // MLX default: 5e-5 instead of 1e-4
        self.batchSize = 2  // MLX safe default on M-series: batch size 2
        self.numberOfEpochs = 1  // Safer default for first run
        self.outputDirectory = "models/"
        self.datasetPath = "data/unified_train_dataset.jsonl"
        self.additionalParameters = [:]
        self.useLowMemoryMode = true
        self.maxSequenceLength = 256
        self.loraRank = 8
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
        guard modelName.contains(":") == false else {
            throw ConfigurationError.invalidModelFormat
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

// MARK: - Training Estimation
extension FineTuningConfigurationModel {
    /// Calculates total number of training steps
    var totalSteps: Int {
        guard datasetSize > 0, batchSize > 0 else { return 0 }
        return (datasetSize / batchSize) * numberOfEpochs
    }
    
    /// Estimates training time in seconds (conservative and optimistic)
    /// MLX on Apple Silicon is faster than traditional frameworks
    /// Returns (conservative, optimistic) time estimates in seconds
    func estimatedTrainingTime() -> (conservative: TimeInterval, optimistic: TimeInterval) {
        let steps = totalSteps
        guard steps > 0 else { return (0, 0) }
        
        // MLX with batch_size=2, seq_length=256: ~4-6 seconds per step
        // Varies based on memory mode and hardware
        let baseTimePerStep: Double
        if useLowMemoryMode {
            // Low-memory mode uses batch_size=1, slightly slower
            baseTimePerStep = 6.0
        } else {
            // Standard mode with batch_size=2
            baseTimePerStep = 4.5
        }
        
        let conservative = Double(steps) * baseTimePerStep * 1.3  // 30% buffer
        let optimistic = Double(steps) * baseTimePerStep * 0.9    // 10% faster
        
        return (conservative, optimistic)
    }
    
    /// Formats time interval into human-readable string
    static func formatTimeEstimate(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "~\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "~\(minutes) minutes"
        } else {
            return "~\(Int(seconds)) seconds"
        }
    }
}

// MARK: - Preview Helpers
extension FineTuningConfigurationModel {
    static let mock: FineTuningConfigurationModel = {
        let config = FineTuningConfigurationModel()
        config.modelName = "Qwen/Qwen2.5-Coder-7B-Instruct"
        config.learningRate = 5e-5
        config.batchSize = 2
        config.numberOfEpochs = 1
        config.datasetSize = 1600
        config.useLowMemoryMode = true
        config.maxSequenceLength = 256
        config.loraRank = 8
        return config
    }()
}
