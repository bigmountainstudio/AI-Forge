// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct WorkflowView: View {
    let project: ProjectModel
    
    var body: some View {
        NavigationStack {
            List(project.workflowSteps) { step in
                Text(step.title)
            }
            .navigationTitle(project.name)
        }
    }
}
