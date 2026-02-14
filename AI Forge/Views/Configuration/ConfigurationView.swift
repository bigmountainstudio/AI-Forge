// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ConfigurationView: View {
    @Bindable var observable: StepDetailObservable
    
    @State private var modelName: String = "qwen2.5-coder:7b"
    @State private var learningRate: String = "0.0001"
    @State private var batchSize: Int = 16
    @State private var numberOfEpochs: Int = 3
    @State private var outputDirectory: String = ""
    @State private var datasetPath: String = ""
    @State private var validationErrors: [String] = []
    @State private var showingOutputPicker = false
    @State private var showingModelNameInfo = false
    @State private var showingLearningRateInfo = false
    @State private var showingBatchSizeInfo = false
    @State private var showingEpochsInfo = false
    @State private var showingOutputDirInfo = false
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    
    init(observable: StepDetailObservable) {
        self.observable = observable
    }
    
    init(observable: StepDetailObservable, validationErrors: [String]) {
        self.observable = observable
        self._validationErrors = State(initialValue: validationErrors)
    }
    
    var body: some View {
        withAlerts(
            VStack(alignment: .leading, spacing: 16) {
                ConfigurationFormView(
                    observable: observable,
                    modelName: $modelName,
                    learningRate: $learningRate,
                    batchSize: $batchSize,
                    numberOfEpochs: $numberOfEpochs,
                    outputDirectory: $outputDirectory,
                    validationErrors: $validationErrors,
                    showingOutputPicker: $showingOutputPicker,
                    showingModelNameInfo: $showingModelNameInfo,
                    showingLearningRateInfo: $showingLearningRateInfo,
                    showingBatchSizeInfo: $showingBatchSizeInfo,
                    showingEpochsInfo: $showingEpochsInfo,
                    showingOutputDirInfo: $showingOutputDirInfo
                )
                
                HStack {
                    Spacer()
                    
                    Button(isSaving ? "Saving..." : "Save Configuration") {
                        saveConfiguration()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(modelName.isEmpty || isSaving)
                    .accessibilityLabel("Save configuration")
                    .accessibilityHint("Saves the fine-tuning configuration and marks this step as complete")
                }
                .padding()
            }
        )
    }
    
    private func withAlerts(_ view: some View) -> some View {
        view
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
            .onAppear {
                loadConfiguration()
            }
            .onChange(of: observable.configuration) {
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
            .alert("Configuration Saved", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your configuration has been saved successfully.")
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
        }
        // Otherwise keep the defaults initialized in @State
        
        // Auto-populate dataset path from Step 2 output if not already set
        if datasetPath.isEmpty, let project = observable.currentProject {
            let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
            let defaultDatasetPath = projectURL.appendingPathComponent("data/unified_finetune_dataset.jsonl").path
            datasetPath = defaultDatasetPath
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
        
        isSaving = true
        Task {
            await observable.updateConfiguration(config)
            isSaving = false
            
            // Only show success if there was no error
            if observable.errorMessage == nil {
                showingSaveSuccess = true
            }
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
