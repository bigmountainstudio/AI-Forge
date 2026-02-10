// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Bindable var projectManager: ProjectManagerObservable
    @Binding var selectedProject: ProjectModel?
    
    var body: some View {
        List(projectManager.projects, selection: $selectedProject) { project in
            Text(project.name)
                .tag(project)
        }
        .navigationTitle("Projects")
        .task {
            await projectManager.loadProjects()
        }
    }
}
