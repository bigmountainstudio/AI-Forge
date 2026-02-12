// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let fileSystemManager: FileSystemManager
    
    @State private var projectName = ""
    @State private var customizationDescription = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $projectName)
                        .accessibilityLabel("Project name")
                        .accessibilityHint("Enter a unique name for your project")
                    TextField("Customization Description", text: $customizationDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Customization description")
                        .accessibilityHint("Provide a detailed description of the domain")
                }
                
                if let error = errorMessage {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Error", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                        .accessibilityLabel("Error: \(error)")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if isCreating {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Creating project...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: errorMessage)
            .animation(.easeInOut(duration: 0.3), value: isCreating)
            .padding()
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel project creation")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(projectName.isEmpty || isCreating)
                    .accessibilityLabel("Create project")
                    .accessibilityHint("Creates a new fine-tuning project with the provided information")
                    .opacity(isCreating ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isCreating)
                }
            }
        }
    }
    
    private func createProject() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                // Validate project name
                guard ValidationHelpers.isValidProjectName(projectName) else {
                    errorMessage = "Project name is invalid. Use only letters, numbers, spaces, hyphens, and underscores."
                    isCreating = false
                    return
                }
                
                // Create project directory
                let projectDirectory: URL
                do {
                    projectDirectory = try fileSystemManager.createProjectDirectory(projectName: projectName)
                } catch {
                    errorMessage = "Failed to create project directory for '\(projectName)': \(error.localizedDescription)"
                    isCreating = false
                    return
                }
                
                // Create project model
                let project = ProjectModel(name: projectName, customizationDescription: customizationDescription)
                project.projectDirectoryPath = projectDirectory.path
                
                // Insert into context
                context.insert(project)
                
                // Save context
                try context.save()
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

#Preview {
    ProjectCreationView(fileSystemManager: FileSystemManager())
        .modelContainer(ProjectModel.preview)
}
