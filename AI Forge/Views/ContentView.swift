// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDelegate) private var appDelegate
    @State private var projectManager: ProjectManagerObservable?
    @State private var selectedProject: ProjectModel?
    @State private var selectedStep: WorkflowStepModel?
    @State private var workflowEngine: WorkflowEngineObservable?
    
    var body: some View {
        NavigationSplitView {
            if let manager = projectManager {
                ProjectListView(
                    projectManager: manager,
                    selectedProject: $selectedProject
                )
            }
        } content: {
            if let project = selectedProject {
                if let engine = workflowEngine {
                    WorkflowView(
                        project: project,
                        selectedStep: $selectedStep,
                        workflowEngine: engine
                    )
                } else {
                    ProgressView()
                }
            } else {
                ContentUnavailableView("Select a Project", systemImage: "folder")
            }
        } detail: {
            if let step = selectedStep,
               let project = selectedProject,
               let engine = workflowEngine {
                StepDetailView(
                    step: step,
                    project: project,
                    workflowEngine: engine
                )
                .id(step.id) // Force refresh when step changes
            } else {
                ContentUnavailableView("Select a Step", systemImage: "list.bullet")
            }
        }
        .onAppear {
            if projectManager == nil {
                projectManager = createProjectManager()
                // Set modelContext in AppDelegate for shutdown handling
                appDelegate?.modelContext = modelContext
            }
        }
        .onChange(of: selectedProject) { _, newProject in
            selectedStep = nil
            if let project = newProject {
                if workflowEngine == nil {
                    workflowEngine = createWorkflowEngine()
                }
                workflowEngine?.loadProject(project)
            }
        }
    }
    
    private func createProjectManager() -> ProjectManagerObservable {
        let fileSystemManager = FileSystemManager()
        return ProjectManagerObservable(modelContext: modelContext, fileSystemManager: fileSystemManager)
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

#Preview("With Project") {
    ContentView()
        .modelContainer(ProjectModel.preview)
}

#Preview("No Project") {
    ContentView()
        .modelContainer(ProjectModel.emptyPreview)
}
