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
        Group {
            if projectManager.isLoading {
                ProgressView("Loading projects...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if projectManager.projects.isEmpty {
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
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                .animation(.easeInOut(duration: 0.3), value: projectManager.projects.count)
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
        .onDeleteCommand {
            if let project = selectedProject {
                projectToDelete = project
                showingDeleteConfirmation = true
            }
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
