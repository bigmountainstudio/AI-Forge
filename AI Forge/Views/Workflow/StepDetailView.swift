// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct StepDetailView: View {
    let step: WorkflowStepModel
    let project: ProjectModel
    let workflowEngine: WorkflowEngineObservable
    
    @State private var stepObservable: StepDetailObservable?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Step header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.title)
                            .font(.title)
                        
                        Text(step.stepDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    if let observable = stepObservable {
                        HStack {
                            if step.status == .pending || step.status == .failed || step.status == .completed {
                                Button(step.status == .completed ? "Re-Execute Step" : "Execute Step", systemImage: "play.circle") {
                                    Task {
                                        await observable.executeStep()
                                    }
                                }
                                .disabled(observable.isExecuting)
                                .accessibilityLabel(step.status == .completed ? "Re-execute step" : "Execute step")
                                .accessibilityHint("Runs the Python script for this workflow step")
                            }
                            
                            if observable.isExecuting {
                                Button("Cancel", systemImage: "stop.circle") {
                                    Task {
                                        await observable.cancelExecution()
                                    }
                                }
                                .accessibilityLabel("Cancel execution")
                                .accessibilityHint("Stops the currently running script")
                                
                                ProgressView()
                                    .padding(.leading)
                                    .accessibilityLabel("Executing step")
                            }
                        }
                        .padding()
                        .animation(.easeInOut(duration: 0.3), value: observable.isExecuting)
                        .animation(.easeInOut(duration: 0.3), value: step.status)
                    }
                }
                
                // Step-specific content
                if let observable = stepObservable {
                    stepContent(for: step.stepNumber, observable: observable)
                        .padding()
                }
                
                // Training progress (for fine-tuning step)
                if let observable = stepObservable, 
                   step.stepNumber == 4,
                   observable.isExecuting,
                   observable.totalTrainingSteps > 0 {
                    TrainingProgressView(
                        currentStep: observable.currentTrainingStep,
                        totalSteps: observable.totalTrainingSteps,
                        estimatedTimeRemaining: observable.estimatedTimeRemaining
                    )
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Execution output
                if let observable = stepObservable, observable.executionOutput.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output")
                            .font(.headline)
                        
                        ScrollView {
                            Text(observable.executionOutput)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(height: 200)
                        .background(.regularMaterial, in: .rect(cornerRadius: 8))
                    }
                    .padding()
                }
                
                // Error message
                if let observable = stepObservable, let error = observable.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(.red.opacity(0.1), in: .rect(cornerRadius: 8))
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
        }
        .onAppear {
            if stepObservable == nil {
                let fileSystemManager = FileSystemManager()
                let pythonExecutor = PythonScriptExecutor()
                
                stepObservable = StepDetailObservable(
                    workflowEngine: workflowEngine,
                    fileSystemManager: fileSystemManager,
                    pythonExecutor: pythonExecutor
                )
                
                // Set loading state immediately for dataset step
                if step.stepNumber == 2 {
                    stepObservable?.isLoadingDataset = true
                }
                
                Task {
                    await stepObservable?.loadStep(step, project: project)
                }
            }
        }
    }
    
    @ViewBuilder
    private func stepContent(for stepNumber: Int, observable: StepDetailObservable) -> some View {
        switch stepNumber {
        case 1:
            SourceFilesView(observable: observable)
        case 2:
            DatasetView(observable: observable)
        case 3:
            ConfigurationView(observable: observable)
        case 4:
            RunFineTuningView(observable: observable)
        default:
            EmptyView()
        }
    }
}

#Preview("Step 1") {
    @Previewable @State var container = ProjectModel.preview
    
    let context = container.mainContext
    let projects = try! context.fetch(FetchDescriptor<ProjectModel>())
    let project = projects.first!
    let step = project.workflowSteps[0]
    
    return StepDetailView(
        step: step,
        project: project,
        workflowEngine: WorkflowEngineObservable(
            modelContext: context,
            pythonExecutor: PythonScriptExecutor(),
            fileSystemManager: FileSystemManager()
        )
    )
    .modelContainer(container)
}
