// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Bindable var projectManager: ProjectManagerObservable
    @Binding var selectedProject: ProjectModel?
    @State private var showingCreateProject = false
    
    var body: some View {
        List(projectManager.projects, selection: $selectedProject) { project in
            ProjectRowView(project: project)
                .tag(project)
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            ProjectCreationView(projectManager: projectManager)
        }
        .task {
            await projectManager.loadProjects()
        }
    }
}

#Preview {
    NavigationStack {
        ProjectListView(
            projectManager: ProjectManagerObservable(
                modelContext: ProjectModel.preview.mainContext,
                fileSystemManager: FileSystemManager()
            ),
            selectedProject: .constant(nil)
        )
    }
    .modelContainer(ProjectModel.preview)
}
