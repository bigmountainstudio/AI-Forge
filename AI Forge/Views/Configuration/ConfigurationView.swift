// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ConfigurationView: View {
    @Bindable var observable: StepDetailObservable
    
    @State private var modelName: String = "Qwen/Qwen2.5-Coder-7B-Instruct"
    @State private var learningRate: String = "5e-5"
    @State private var batchSize: Int = 2
    @State private var numberOfEpochs: Int = 1
    @State private var outputDirectory: String = ""
    @State private var datasetPath: String = ""
    @State private var validationErrors: [String] = []
    @State private var showingOutputPicker = false
    @State private var showingModelNameInfo = false
    @State private var showingLearningRateInfo = false
    @State private var showingBatchSizeInfo = false
    @State private var showingEpochsInfo = false
    @State private var showingOutputDirInfo = false
    
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
            .alert("Model Selection", isPresented: $showingModelNameInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Select a HuggingFace model for MLX fine-tuning on Apple Silicon. Recommended 7B models for M-series Macs:\n\n• Qwen/Qwen2.5-Coder-7B-Instruct\n• mistralai/Mistral-7B-Instruct-v0.1\n• meta-llama/Llama-2-7b-hf\n\nLatest models work best for up-to-date knowledge. Larger models may require more memory.")
            }
            .alert("Learning Rate", isPresented: $showingLearningRateInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Controls training speed. MLX default: 5e-5 (0.00005)\n\n• Lower (1e-5): More stable but slower\n• Higher (1e-4): Faster but may diverge\n\nFor LoRA, 5e-5 is optimal. Avoid values > 1e-3.")
            }
            .alert("Batch Size", isPresented: $showingBatchSizeInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Examples processed per step. MLX safe defaults:\n\n• Batch 1-2: Most stable (recommended)\n• Batch 2-4: Good balance\n• Batch >4: Higher memory usage\n\nM2 with 64GB RAM: Start with 2, reduce to 1 if OOM.\nUse Low-Memory Mode for safety.")
            }
            .alert("Number of Epochs", isPresented: $showingEpochsInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Times through entire dataset.\n\n• Start with 1 epoch to verify setup\n• 2-3 epochs for good learning\n• >3 epochs risks overfitting\n\nMonitor training loss—stop if plateau or loss increases.")
            }
            .alert("Output Directory", isPresented: $showingOutputDirInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Folder for LoRA adapters (~100-500MB). MLX saves adapters separately from base model.\n\nDefault: models/adapters/\n\nChoose location with sufficient space.")
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
