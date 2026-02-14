// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ConfigurationView: View {
    @Bindable var observable: StepDetailObservable
    
    @State private var modelName: String = ""
    @State private var learningRate: String = ""
    @State private var batchSize: Int = 8
    @State private var numberOfEpochs: Int = 3
    @State private var outputDirectory: String = ""
    @State private var datasetPath: String = ""
    @State private var validationErrors: [String] = []
    @State private var showingOutputPicker = false
    @State private var showingDatasetPicker = false
    @State private var showingModelNameInfo = false
    @State private var showingLearningRateInfo = false
    @State private var showingBatchSizeInfo = false
    @State private var showingEpochsInfo = false
    @State private var showingOutputDirInfo = false
    @State private var showingDatasetPathInfo = false
    
    init(observable: StepDetailObservable) {
        self.observable = observable
    }
    
    init(observable: StepDetailObservable, validationErrors: [String]) {
        self.observable = observable
        self._validationErrors = State(initialValue: validationErrors)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                Section("Model Configuration") {
                    HStack {
                        TextField("Model Name", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Model name")
                            .accessibilityHint("Enter the name of the model to fine-tune")
                        
                        Button {
                            showingModelNameInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Model name information")
                        .accessibilityHint("Tap to learn more about the model name parameter")
                    }
                    
                    HStack {
                        Text("Learning Rate")
                        Spacer()
                        TextField("0.0001", text: $learningRate)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .accessibilityLabel("Learning rate")
                            .accessibilityHint("Enter the learning rate as a decimal number")
                        
                        Button {
                            showingLearningRateInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Learning rate information")
                        .accessibilityHint("Tap to learn more about the learning rate parameter")
                    }
                    
                    HStack {
                        Stepper("Batch Size: \(batchSize)", value: $batchSize, in: 1...128)
                            .accessibilityLabel("Batch size")
                            .accessibilityValue("\(batchSize)")
                            .accessibilityHint("Adjust the batch size between 1 and 128")
                        
                        Button {
                            showingBatchSizeInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Batch size information")
                        .accessibilityHint("Tap to learn more about the batch size parameter")
                    }
                    
                    HStack {
                        Stepper("Number of Epochs: \(numberOfEpochs)", value: $numberOfEpochs, in: 1...100)
                            .accessibilityLabel("Number of epochs")
                            .accessibilityValue("\(numberOfEpochs)")
                            .accessibilityHint("Adjust the number of training epochs between 1 and 100")
                        
                        Button {
                            showingEpochsInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Number of epochs information")
                        .accessibilityHint("Tap to learn more about the epochs parameter")
                    }
                }
                
                Section("Paths") {
                    HStack {
                        TextField("Output Directory", text: $outputDirectory)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Output directory")
                            .accessibilityHint("Path where model checkpoints will be saved")
                        
                        Button {
                            showingOutputPicker = true
                        } label: {
                            Image(systemName: "folder")
                        }
                        .accessibilityLabel("Choose output directory")
                        .accessibilityHint("Opens a folder picker")
                        
                        Button {
                            showingOutputDirInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Output directory information")
                        .accessibilityHint("Tap to learn more about the output directory")
                    }
                    
                    HStack {
                        TextField("Dataset Path", text: $datasetPath)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Dataset path")
                            .accessibilityHint("Path to the training dataset file")
                        
                        Button {
                            showingDatasetPicker = true
                        } label: {
                            Image(systemName: "doc")
                        }
                        .accessibilityLabel("Choose dataset file")
                        .accessibilityHint("Opens a file picker")
                        
                        Button {
                            showingDatasetPathInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dataset path information")
                        .accessibilityHint("Tap to learn more about the dataset path")
                    }
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
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                
                Button("Save Configuration") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(modelName.isEmpty)
                .accessibilityLabel("Save configuration")
                .accessibilityHint("Saves the fine-tuning configuration and marks this step as complete")
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingOutputPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                outputDirectory = url.path
            case .failure(let error):
                observable.errorMessage = "Failed to select folder: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showingDatasetPicker,
            allowedContentTypes: [.data, .json, .text]
        ) { result in
            switch result {
            case .success(let url):
                datasetPath = url.path
            case .failure(let error):
                observable.errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
        .onAppear {
            loadConfiguration()
        }
        .alert("Model Name", isPresented: $showingModelNameInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier or name of the base language model to fine-tune. Examples: 'qwen2.5-coder:7b', 'llama-2-7b-chat'. This determines the starting point for your fine-tuning.")
        }
        .alert("Learning Rate", isPresented: $showingLearningRateInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Controls how much the model's weights are updated during training. Lower values (like 0.0001) mean slower but more stable learning. Higher values learn faster but may be unstable. Typical range: 0.00001 to 0.001.")
        }
        .alert("Batch Size", isPresented: $showingBatchSizeInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Number of training examples processed together in one forward/backward pass. Larger batches provide more stable gradients but require more memory. Smaller batches can fit better on limited hardware. Typical range: 1-32 for consumer GPUs.")
        }
        .alert("Number of Epochs", isPresented: $showingEpochsInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("How many times the model sees the entire training dataset. More epochs can improve learning but risk overfitting. Start with 3-5 epochs and evaluate performance. You can always continue training later.")
        }
        .alert("Output Directory", isPresented: $showingOutputDirInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Directory where fine-tuned model checkpoints and the final model will be saved. Choose a location with sufficient storage space (models can be several GB). The directory will be created if it doesn't exist.")
        }
        .alert("Dataset Path", isPresented: $showingDatasetPathInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Path to the training dataset file in JSONL format. This file contains instruction-tuning examples with 'instruction', 'input', and 'output' fields. Generated by the dataset creation scripts in the workflow.")
        }
    }
    
    private func loadConfiguration() {
        if let config = observable.configuration {
            modelName = config.modelName
            learningRate = String(config.learningRate)
            batchSize = config.batchSize
            numberOfEpochs = config.numberOfEpochs
            outputDirectory = config.outputDirectory
            datasetPath = config.datasetPath
        } else {
            // Set defaults
            learningRate = "0.0001"
            batchSize = 8
            numberOfEpochs = 3
        }
    }
    
    private func saveConfiguration() {
        validationErrors = []
        
        // Validate inputs
        guard modelName.isEmpty == false else {
            validationErrors.append("Model name is required")
            return
        }
        
        guard let learningRateValue = Double(learningRate), learningRateValue > 0 else {
            validationErrors.append("Learning rate must be a positive number")
            return
        }
        
        guard batchSize > 0 else {
            validationErrors.append("Batch size must be greater than 0")
            return
        }
        
        guard numberOfEpochs > 0 else {
            validationErrors.append("Number of epochs must be greater than 0")
            return
        }
        
        // Create or update configuration
        let config = observable.configuration ?? FineTuningConfigurationModel()
        config.modelName = modelName
        config.learningRate = learningRateValue
        config.batchSize = batchSize
        config.numberOfEpochs = numberOfEpochs
        config.outputDirectory = outputDirectory
        config.datasetPath = datasetPath
        
        Task {
            await observable.updateConfiguration(config)
        }
    }
}

#Preview("Normal State") {
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
    
    ConfigurationView(observable: observable)
}

#Preview("Error State") {
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
    
    ConfigurationView(observable: observable, validationErrors: ["Model name is required", "Learning rate must be a positive number"])
}
