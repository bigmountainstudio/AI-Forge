// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct WorkflowView: View {
    let project: ProjectModel
    @Binding var selectedStep: WorkflowStepModel?
    let workflowEngine: WorkflowEngineObservable
    
    var body: some View {
        List(project.workflowSteps.sorted(by: { $0.stepNumber < $1.stepNumber }), selection: $selectedStep) { step in
            WorkflowStepRowView(step: step)
                .tag(step)
        }
        .navigationTitle(project.name)
        .onAppear {
            workflowEngine.loadProject(project)
        }
    }
}

#Preview {
    NavigationStack {
        WorkflowView(
            project: ProjectModel.mock,
            selectedStep: .constant(nil),
            workflowEngine: WorkflowEngineObservable(
                modelContext: ProjectModel.preview.mainContext,
                pythonExecutor: PythonScriptExecutor(),
                fileSystemManager: FileSystemManager()
            )
        )
    }
    .modelContainer(ProjectModel.preview)
}
