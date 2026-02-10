// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Bindable var projectManager: ProjectManagerObservable
    @Binding var selectedProject: ProjectModel?
    @State private var showingCreateProject = false
    @State private var projectToDelete: ProjectModel?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List(projectManager.projects, selection: $selectedProject) { project in
            ProjectRowView(project: project)
                .tag(project)
                .contextMenu {
                    Button(role: .destructive) {
                        projectToDelete = project
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                }
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
        .alert("Delete Project", isPresented: $showingDeleteConfirmation, presenting: projectToDelete) { project in
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
            
            Button("Delete", role: .destructive) {
                Task {
                    if selectedProject?.id == project.id {
                        selectedProject = nil
                    }
                    try? await projectManager.deleteProject(project)
                    projectToDelete = nil
                }
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone.")
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
