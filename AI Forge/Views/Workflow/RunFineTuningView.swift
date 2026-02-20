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
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MLX Fine-Tuning on Apple Silicon")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Optimized for M-series Macs with native Metal acceleration. Expect 4-6 seconds per training step.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This process may take a long time")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Depending on your dataset size and hardware, fine-tuning can take anywhere from several minutes to several hours.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You can cancel at any time")
                            .font(.caption.weight(.semibold))
                        
                        Text("Use the Cancel button above to stop the process. Your progress will be saved.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
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
            Text("Configuration (MLX)")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                configRow(label: "Model", value: config.modelName)
                Divider()
                configRow(label: "Learning Rate", value: String(format: "%.0e", config.learningRate))
                Divider()
                configRow(label: "Batch Size", value: "\(config.batchSize)")
                Divider()
                configRow(label: "Epochs", value: "\(config.numberOfEpochs)")
                Divider()
                configRow(label: "Max Sequence Length", value: "\(config.maxSequenceLength) tokens")
                Divider()
                configRow(label: "LoRA Rank", value: "\(config.loraRank)")
                Divider()
                configRow(label: "Low-Memory Mode", value: config.useLowMemoryMode ? "Enabled" : "Disabled")
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
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Estimated Duration")
                .font(.headline)
            
            if steps > 0 {
                VStack(alignment: .leading, spacing: 8) {
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
                    Text("MLX on Apple Silicon: ~4-6 sec/step. Optimistic uses 4.5 sec/step, conservative uses 5.85 sec/step (+30% buffer).")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 8))
            } else {
                Label {
                    Text("Generate a dataset in Step 2 to see the time estimate")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.red.opacity(0.1), in: .rect(cornerRadius: 8))
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
    
    private var memoryErrorGuidance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your GPU ran out of memory during training. Try these solutions:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                solutionRow(
                    icon: "arrow.down.circle.fill",
                    title: "Reduce Batch Size",
                    description: "Go to Step 3 and reduce the batch size (try 8, 4, or even 2)",
                    priority: .high
                )
                
                solutionRow(
                    icon: "chart.line.downtrend.xyaxis",
                    title: "Reduce Dataset Size",
                    description: "Use fewer training examples in your dataset",
                    priority: .medium
                )
                
                solutionRow(
                    icon: "cube.box.fill",
                    title: "Use a Smaller Model",
                    description: "Select a smaller base model (e.g., 7B instead of 13B parameters)",
                    priority: .medium
                )
                
                solutionRow(
                    icon: "memorychip.fill",
                    title: "Free Up GPU Memory",
                    description: "Close other applications using GPU resources",
                    priority: .low
                )
            }
        }
        .padding()
        .background(.orange.opacity(0.1), in: .rect(cornerRadius: 8))
    }
    
    private func solutionRow(icon: String, title: String, description: String, priority: Priority) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(priority.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    if priority == .high {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priority.color, in: .capsule)
                    }
                }
                
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .orange
            case .low: return .blue
            }
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

#Preview("Error - Ollama Not Found") {
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
    observable.errorMessage = """
    Error: Ollama is not installed or not accessible in PATH
    
    Please ensure Ollama is installed:
      - Download from: https://ollama.ai
      - Or install via: brew install ollama
    
    After installation, restart your terminal or add Ollama to your PATH
    """
    
    return RunFineTuningView(observable: observable)
        .padding()
}

#Preview("Error - Out of Memory") {
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
    observable.errorMessage = """
    libc++abi: terminating due to uncaught exception of type std::runtime_error: [METAL] Command buffer execution failed: Insufficient Memory (00000008:kIOGPUCommandBufferCallbackErrorOutOfMemory)
    /Applications/Xcode.app/Contents/Developer/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/multiprocessing/resource_tracker.py:216: UserWarning: resource_tracker: There appear to be 1 leaked semaphore objects to clean up at shutdown
      warnings.warn('resource_tracker: There appear to be %d '
    """
    
    return RunFineTuningView(observable: observable)
        .padding()
}
