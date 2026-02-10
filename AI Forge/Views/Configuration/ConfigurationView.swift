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
                    
                    HStack {
                        Text("Learning Rate")
                        Spacer()
                        TextField("0.0001", text: $learningRate)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    
                    Stepper("Batch Size: \(batchSize)", value: $batchSize, in: 1...128)
                    
                    Stepper("Number of Epochs: \(numberOfEpochs)", value: $numberOfEpochs, in: 1...100)
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
                    }
                    
                    HStack {
                        TextField("Dataset Path", text: $datasetPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            showingDatasetPicker = true
                        } label: {
                            Image(systemName: "doc")
                        }
                    }
                }
                
                if validationErrors.isEmpty == false {
                    Section("Validation Errors") {
                        ForEach(validationErrors, id: \.self) { error in
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
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
