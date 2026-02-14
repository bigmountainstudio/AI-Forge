// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import SwiftUI

struct RunFineTuningView: View {
    @Bindable var observable: StepDetailObservable
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                
                Button("Cancel", systemImage: "xmark.circle.fill", role: .destructive) {
                    Task {
                        await observable.cancelExecution()
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .buttonStyle(.bordered)
                .disabled(observable.isExecuting == false)
            }
            
            // Timeline warning
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This process may take a long time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Depending on your dataset size and hardware, fine-tuning can take anywhere from several minutes to several hours.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You can cancel at any time")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("Use the Cancel button above to stop the process. Your progress will be saved.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(.blue.opacity(0.1), in: .rect(cornerRadius: 8))
            
            // Configuration display
            if let config = observable.configuration {
                configurationSection(config)
            }
            
            // Time estimate (before execution)
            if let config = observable.configuration, observable.isExecuting == false {
                timeEstimateSection(config)
            }
            
            // Execution status
            if observable.isExecuting {
                executionStatusSection
            }
            
            Spacer()
        }
    }
    
    private func configurationSection(_ config: FineTuningConfigurationModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                configRow(label: "Model", value: config.modelName)
                Divider()
                configRow(label: "Learning Rate", value: String(format: "%.6f", config.learningRate))
                Divider()
                configRow(label: "Batch Size", value: "\(config.batchSize)")
                Divider()
                configRow(label: "Epochs", value: "\(config.numberOfEpochs)")
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
        }
    }
    
    private func configRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.caption)
    }
    
    private func timeEstimateSection(_ config: FineTuningConfigurationModel) -> some View {
        let (conservative, optimistic) = config.estimatedTrainingTime()
        let steps = config.totalSteps
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Estimated Duration")
                .font(.headline)
            
            if steps > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    // Steps information
                    HStack {
                        Label("Training Steps", systemImage: "number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(steps) steps")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    
                    Divider()
                    
                    // Time estimate range
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Optimistic")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(FineTuningConfigurationModel.formatTimeEstimate(optimistic))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Text("Conservative")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(FineTuningConfigurationModel.formatTimeEstimate(conservative))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    // Disclaimer
                    Text("Actual time varies based on hardware performance and system load. Optimistic uses 5 sec/step, conservative uses 10 sec/step.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        
                        Text("Load a dataset to see time estimate")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.blue.opacity(0.05), in: .rect(cornerRadius: 8))
            }
        }
    }
    
    private var executionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Execution Status")
                .font(.headline)
            
            HStack(spacing: 12) {
                ProgressView()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fine-tuning in progress...")
                        .font(.subheadline)
                    
                    if let startTime = observable.trainingStartTime {
                        let elapsed = Date().timeIntervalSince(startTime)
                        Text("Elapsed: \(formatDuration(elapsed))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

#Preview("Ready to Execute - With Estimate") {
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    let workflowEngine = WorkflowEngineObservable(
        modelContext: ProjectModel.preview.mainContext,
        pythonExecutor: pythonExecutor,
        fileSystemManager: fileSystemManager
    )
    
    let observable = StepDetailObservable(
        workflowEngine: workflowEngine,
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    
    observable.configuration = .mock
    
    return RunFineTuningView(observable: observable)
        .padding()
}

#Preview("Ready to Execute - No Dataset Yet") {
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    let workflowEngine = WorkflowEngineObservable(
        modelContext: ProjectModel.preview.mainContext,
        pythonExecutor: pythonExecutor,
        fileSystemManager: fileSystemManager
    )
    
    let observable = StepDetailObservable(
        workflowEngine: workflowEngine,
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    
    let config = FineTuningConfigurationModel()
    config.modelName = "gpt-3.5-turbo"
    config.learningRate = 0.0001
    config.batchSize = 16
    config.numberOfEpochs = 3
    config.datasetSize = 0  // No dataset loaded yet
    observable.configuration = config
    
    return RunFineTuningView(observable: observable)
        .padding()
}

#Preview("Executing") {
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    let workflowEngine = WorkflowEngineObservable(
        modelContext: ProjectModel.preview.mainContext,
        pythonExecutor: pythonExecutor,
        fileSystemManager: fileSystemManager
    )
    
    let observable = StepDetailObservable(
        workflowEngine: workflowEngine,
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    
    observable.configuration = .mock
    observable.isExecuting = true
    observable.trainingStartTime = Date().addingTimeInterval(-125)
    
    return RunFineTuningView(observable: observable)
        .padding()
}
