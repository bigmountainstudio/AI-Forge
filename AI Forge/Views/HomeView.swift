// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var projectManager: ProjectManagerObservable?
    @State private var selectedProject: ProjectModel?
    
    var body: some View {
        NavigationSplitView {
            ProjectListView(
                projectManager: projectManager ?? createProjectManager(),
                selectedProject: $selectedProject
            )
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
            }
        }
    }
    
    private func createProjectManager() -> ProjectManagerObservable {
        let fileSystemManager = FileSystemManager()
        return ProjectManagerObservable(modelContext: modelContext, fileSystemManager: fileSystemManager)
    }
}

#Preview {
    HomeView()
        .modelContainer(ProjectModel.preview)
}
