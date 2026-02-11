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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                Section("Model Configuration") {
                    TextField("Model Name", text: $modelName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Model name")
                        .accessibilityHint("Enter the name of the model to fine-tune")
                    
                    HStack {
                        Text("Learning Rate")
                        Spacer()
                        TextField("0.0001", text: $learningRate)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .accessibilityLabel("Learning rate")
                            .accessibilityHint("Enter the learning rate as a decimal number")
                    }
                    
                    Stepper("Batch Size: \(batchSize)", value: $batchSize, in: 1...128)
                        .accessibilityLabel("Batch size")
                        .accessibilityValue("\(batchSize)")
                        .accessibilityHint("Adjust the batch size between 1 and 128")
                    
                    Stepper("Number of Epochs: \(numberOfEpochs)", value: $numberOfEpochs, in: 1...100)
                        .accessibilityLabel("Number of epochs")
                        .accessibilityValue("\(numberOfEpochs)")
                        .accessibilityHint("Adjust the number of training epochs between 1 and 100")
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
                        .padding(.vertical, 4)
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
        .padding()
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

#Preview {
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
