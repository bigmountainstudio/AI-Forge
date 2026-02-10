// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var projectManager: ProjectManagerObservable
    
    @State private var projectName = ""
    @State private var domainName = ""
    @State private var domainDescription = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $projectName)
                    TextField("Domain Name", text: $domainName)
                    TextField("Domain Description", text: $domainDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(projectName.isEmpty || domainName.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createProject() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await projectManager.createProject(
                    name: projectName,
                    domainName: domainName,
                    domainDescription: domainDescription
                )
                await projectManager.loadProjects()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

#Preview {
    ProjectCreationView(
        projectManager: ProjectManagerObservable(
            modelContext: ProjectModel.preview.mainContext,
            fileSystemManager: FileSystemManager()
        )
    )
}
