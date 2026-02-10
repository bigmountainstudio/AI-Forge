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
            VStack(alignment: .leading, spacing: 20) {
                // Step header
                VStack(alignment: .leading, spacing: 8) {
                    Text(step.title)
                        .font(.title)
                    
                    Text(step.stepDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                // Step-specific content
                if let observable = stepObservable {
                    stepContent(for: step.stepNumber, observable: observable)
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
                        }
                        .frame(height: 200)
                        .background(.regularMaterial, in: .rect(cornerRadius: 8))
                    }
                    .padding()
                }
                
                // Error message
                if let observable = stepObservable, let error = observable.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                // Action buttons
                if let observable = stepObservable {
                    HStack {
                        if step.status == .failed {
                            Button("Retry") {
                                Task {
                                    await observable.executeStep()
                                }
                            }
                        }
                        
                        if step.status == .pending || step.status == .failed {
                            Button("Execute Step") {
                                Task {
                                    await observable.executeStep()
                                }
                            }
                            .disabled(observable.isExecuting)
                        }
                        
                        if observable.isExecuting {
                            Button("Cancel") {
                                Task {
                                    await observable.cancelExecution()
                                }
                            }
                            
                            ProgressView()
                                .padding(.leading)
                        }
                    }
                    .padding()
                }
            }
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
        case 3:
            ConfigurationView(observable: observable)
        default:
            EmptyView()
        }
    }
}

#Preview {
    let project = ProjectModel.mock
    let step = project.workflowSteps[0]
    
    StepDetailView(
        step: step,
        project: project,
        workflowEngine: WorkflowEngineObservable(
            modelContext: ProjectModel.preview.mainContext,
            pythonExecutor: PythonScriptExecutor(),
            fileSystemManager: FileSystemManager()
        )
    )
}
