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
    @State private var showingCreateProject = false
    
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
                    ProgressView("Loading workflow...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ContentUnavailableView {
                    Label("Select a Project", systemImage: "folder")
                } description: {
                    Text("Choose a project from the sidebar to view its workflow steps")
                }
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
                ContentUnavailableView {
                    Label("Select a Step", systemImage: "list.bullet")
                } description: {
                    Text("Choose a workflow step to view details and execute actions")
                }
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
        .sheet(isPresented: $showingCreateProject) {
            if let manager = projectManager {
                ProjectCreationView(projectManager: manager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewProject)) { _ in
            showingCreateProject = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveCurrentProject)) { _ in
            saveCurrentProject()
        }
    }
    
    func createNewProject() {
        showingCreateProject = true
    }
    
    private func saveCurrentProject() {
        guard let project = selectedProject,
              let manager = projectManager else { return }
        
        do {
            try manager.saveProject(project)
        } catch {
            // Error is already logged in ProjectManagerObservable
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
