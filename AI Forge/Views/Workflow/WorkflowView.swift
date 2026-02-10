// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct WorkflowView: View {
    @Environment(\.modelContext) private var modelContext
    let project: ProjectModel
    
    @State private var workflowEngine: WorkflowEngineObservable?
    @State private var selectedStep: WorkflowStepModel?
    
    var body: some View {
        NavigationStack {
            List(project.workflowSteps, selection: $selectedStep) { step in
                NavigationLink(value: step) {
                    WorkflowStepRowView(step: step)
                }
            }
            .navigationTitle(project.name)
            .navigationDestination(for: WorkflowStepModel.self) { step in
                StepDetailView(
                    step: step,
                    project: project,
                    workflowEngine: workflowEngine ?? createWorkflowEngine()
                )
            }
        }
        .onAppear {
            if workflowEngine == nil {
                workflowEngine = createWorkflowEngine()
                workflowEngine?.loadProject(project)
            }
        }
    }
    
    private func createWorkflowEngine() -> WorkflowEngineObservable {
        let fileSystemManager = FileSystemManager()
        let pythonExecutor = PythonScriptExecutor()
        return WorkflowEngineObservable(
            modelContext: modelContext,
            pythonExecutor: pythonExecutor,
            fileSystemManager: fileSystemManager
        )
    }
}

#Preview {
    WorkflowView(project: ProjectModel.mock)
        .modelContainer(ProjectModel.preview)
}
