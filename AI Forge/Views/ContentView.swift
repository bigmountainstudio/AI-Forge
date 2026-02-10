// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDelegate) private var appDelegate
    @State private var projectManager: ProjectManagerObservable?
    @State private var selectedProject: ProjectModel?
    
    var body: some View {
        NavigationSplitView {
            if let manager = projectManager {
                ProjectListView(
                    projectManager: manager,
                    selectedProject: $selectedProject
                )
            }
        } detail: {
            if let project = selectedProject {
                WorkflowView(project: project)
            } else {
                Text("Select a project to begin")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            if projectManager == nil {
                projectManager = createProjectManager()
                // Set modelContext in AppDelegate for shutdown handling
                appDelegate?.modelContext = modelContext
            }
        }
    }
    
    private func createProjectManager() -> ProjectManagerObservable {
        let fileSystemManager = FileSystemManager()
        return ProjectManagerObservable(modelContext: modelContext, fileSystemManager: fileSystemManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(ProjectModel.preview)
}
