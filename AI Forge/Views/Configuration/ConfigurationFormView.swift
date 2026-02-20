// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ConfigurationFormView: View {
    @Bindable var observable: StepDetailObservable
    
    @Binding var modelName: String
    @Binding var learningRate: String
    @Binding var batchSize: Int
    @Binding var numberOfEpochs: Int
    @Binding var outputDirectory: String
    @Binding var validationErrors: [String]
    @Binding var showingOutputPicker: Bool
    @Binding var showingModelNameInfo: Bool
    @Binding var showingLearningRateInfo: Bool
    @Binding var showingBatchSizeInfo: Bool
    @Binding var showingEpochsInfo: Bool
    @Binding var showingOutputDirInfo: Bool
    
    @State private var modelSelection: String = "Qwen/Qwen2.5-Coder-7B-Instruct"
    // MLX uses HuggingFace models instead of Ollama
    let modelOptions = [
        "Qwen/Qwen2.5-Coder-7B-Instruct",
        "mistralai/Mistral-7B-Instruct-v0.1",
        "meta-llama/Llama-2-7b-hf",
        "Other"
    ]
    
    var body: some View {
        Form {
            Section("Model Configuration (MLX Fine-Tuning)") {
                HStack {
                    Picker("Model", selection: $modelSelection) {
                        ForEach(modelOptions, id: \.self) { option in
                            Text(option)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Model name (HuggingFace)")
                    .accessibilityHint("Select a HuggingFace model for MLX fine-tuning")
                    .onChange(of: modelSelection) { oldValue, newValue in
                        if newValue != "Other" {
                            modelName = newValue
                        }
                    }
                    
                    Button {
                        showingModelNameInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Model name information")
                    .accessibilityHint("Tap to learn more about available models")
                }
                
                if modelSelection == "Other" {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("HuggingFace Model ID", text: $modelName)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Custom model name")
                                .accessibilityHint("Enter a HuggingFace model ID (e.g., Qwen/Qwen2.5-Coder-7B)")
                            Spacer()
                        }
                        
                        if modelName.contains(":") {
                            Text("⚠️ MLX requires a HuggingFace repo ID, not an Ollama name.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                HStack {
                    Text("Learning Rate")
                    TextField("5e-5", text: $learningRate)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .accessibilityLabel("Learning rate")
                        .accessibilityHint("Default for MLX: 5e-5")
                    
                    Button {
                        showingLearningRateInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Learning rate information")
                }
                
                HStack {
                    Text("Batch Size")
                    Text("\(batchSize)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper("", value: $batchSize, in: 1...8)
                        .labelsHidden()
                        .accessibilityLabel("Batch size")
                        .accessibilityValue("\(batchSize)")
                        .accessibilityHint("MLX safe range: 1-8 (lower = more stable)")
                    
                    Button {
                        showingBatchSizeInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Batch size information")
                }
                
                HStack {
                    Text("Number of Epochs")
                    Text("\(numberOfEpochs)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper("", value: $numberOfEpochs, in: 1...10)
                        .labelsHidden()
                        .accessibilityLabel("Number of epochs")
                        .accessibilityValue("\(numberOfEpochs)")
                        .accessibilityHint("Adjust between 1 and 10")
                    
                    Button {
                        showingEpochsInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Epochs information")
                }
            }
            
            Section("MLX-Specific Options") {
                if let config = observable.configuration {
                    @Bindable var config = config
                    Toggle("Low-Memory Mode", isOn: $config.useLowMemoryMode)
                        .accessibilityHint("Reduces batch size to 1 for more stable training. Recommended for large datasets.")
                    
                    HStack {
                        Text("Max Sequence Length")
                        Text("\(config.maxSequenceLength)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Stepper("", value: $config.maxSequenceLength, in: 128...512, step: 128)
                            .labelsHidden()
                            .accessibilityLabel("Max sequence length")
                            .accessibilityValue("\(config.maxSequenceLength) tokens")
                            .accessibilityHint("Reduce to 128 if getting memory errors")
                    }
                    
                    HStack {
                        Text("LoRA Rank")
                        Text("\(config.loraRank)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Stepper("", value: $config.loraRank, in: 4...32, step: 4)
                            .labelsHidden()
                    }
                }
            }
            
            Section("Paths") {
                HStack {
                    TextField("Output Directory", text: $outputDirectory)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        showingOutputPicker = true
                    } label: {
                        Image(systemName: "folder")
                    }
                    .accessibilityLabel("Choose output directory")
                    
                    Button {
                        showingOutputDirInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Output directory information")
                }
            }
            
            // Training Time Estimate Section
            if let config = observable.configuration, config.datasetSize > 0 {
                Section("Estimated Training Time") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Total Steps", systemImage: "number")
                                .foregroundStyle(.secondary)
                            Text("\(config.totalSteps)")
                                .monospacedDigit()
                                .fontWeight(.medium)
                        }
                        
                        let (conservative, optimistic) = config.estimatedTrainingTime()
                        
                        HStack {
                            Label("Time Range", systemImage: "clock")
                                .foregroundStyle(.secondary)
                            Text("\(FineTuningConfigurationModel.formatTimeEstimate(optimistic)) - \(FineTuningConfigurationModel.formatTimeEstimate(conservative))")
                                .monospacedDigit()
                                .fontWeight(.medium)
                        }
                        
                        Text("MLX on Apple Silicon: ~4-6 seconds/step. Actual time calculated after 10-20 steps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            
            if validationErrors.isEmpty == false {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Validation Errors", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        ForEach(validationErrors, id: \.self) { error in
                            Text("• \(error)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        
                        Text("Please correct the errors above before saving.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    let container = ProjectModel.preview
    let context = container.mainContext
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    
    @Bindable var observable = StepDetailObservable(
        workflowEngine: WorkflowEngineObservable(
            modelContext: context,
            pythonExecutor: pythonExecutor,
            fileSystemManager: fileSystemManager
        ),
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    observable.configuration = FineTuningConfigurationModel.mock
    
    return ConfigurationFormView(
        observable: observable,
        modelName: .constant("Qwen/Qwen2.5-Coder-7B-Instruct"),
        learningRate: .constant("5e-5"),
        batchSize: .constant(2),
        numberOfEpochs: .constant(1),
        outputDirectory: .constant("models/"),
        validationErrors: .constant([]),
        showingOutputPicker: .constant(false),
        showingModelNameInfo: .constant(false),
        showingLearningRateInfo: .constant(false),
        showingBatchSizeInfo: .constant(false),
        showingEpochsInfo: .constant(false),
        showingOutputDirInfo: .constant(false)
    )
    .modelContainer(container)
}
