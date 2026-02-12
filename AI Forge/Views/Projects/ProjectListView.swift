// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProjectModel.updatedAt, order: .reverse) private var projects: [ProjectModel]
    @Binding var selectedProject: ProjectModel?
    @State private var showingCreateProject = false
    @State private var projectToDelete: ProjectModel?
    @State private var showingDeleteConfirmation = false
    
    private let fileSystemManager = FileSystemManager()
    
    var body: some View {
        Group {
            if projects.isEmpty {
                ContentUnavailableView {
                    Label("No Projects", systemImage: "folder.badge.plus")
                } description: {
                    Text("Create a new project to get started with fine-tuning AI models")
                } actions: {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Create first project")
                    .accessibilityHint("Opens a form to create your first fine-tuning project")
                }
            } else {
                List(projects, selection: $selectedProject) { project in
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
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                .animation(.easeInOut(duration: 0.3), value: projects.count)
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
                .accessibilityLabel("Create new project")
                .accessibilityHint("Opens a form to create a new fine-tuning project")
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            ProjectCreationView(fileSystemManager: fileSystemManager)
        }
        .alert("Delete Project", isPresented: $showingDeleteConfirmation, presenting: projectToDelete) { project in
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
            
            Button("Delete", role: .destructive) {
                if selectedProject?.id == project.id {
                    selectedProject = nil
                }
                
                // Delete project directory
                let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
                try? fileSystemManager.deleteProjectDirectory(at: projectURL)
                
                // Delete from context
                context.delete(project)
                try? context.save()
                
                projectToDelete = nil
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone.")
        }
        .onDeleteCommand {
            if let project = selectedProject {
                projectToDelete = project
                showingDeleteConfirmation = true
            }
        }
    }
}

#Preview("With Data") {
    NavigationStack {
        ProjectListView(selectedProject: .constant(nil))
    }
    .modelContainer(ProjectModel.preview)
}

#Preview("No Data") {
    NavigationStack {
        ProjectListView(selectedProject: .constant(nil))
    }
    .modelContainer(ProjectModel.emptyPreview)
}
