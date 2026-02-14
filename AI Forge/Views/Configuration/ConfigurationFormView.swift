// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import UniformTypeIdentifiers

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
    
    @State private var modelSelection: String = ""
    let modelOptions = ["qwen2.5-coder:7b", "qwen2.5-coder:32b", "qwen3-coder:30b", "Other"]
    
    var body: some View {
        Form {
            Section("Model Configuration") {
                HStack {
                    Picker("Model Name", selection: $modelSelection) {
                        ForEach(modelOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Model name")
                    .accessibilityHint("Select a model or choose Other to enter custom name")
                    
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
                
                if modelSelection == "Other" {
                    HStack {
                        TextField("Custom Model Name", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Custom model name")
                            .accessibilityHint("Enter the name of the custom model to fine-tune")
                        Spacer()
                    }
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
        .onAppear {
            if modelOptions.contains(modelName) {
                modelSelection = modelName
            } else {
                modelSelection = "Other"
            }
        }
        .onChange(of: modelSelection) { oldValue, newValue in
            if newValue != "Other" {
                modelName = newValue
            }
        }
    }
}

#Preview {
    
}
