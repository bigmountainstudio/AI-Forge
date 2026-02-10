// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI

struct ProjectRowView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            
            Text(project.domainName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("Step \(project.currentStepIndex + 1) of 6")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                ProgressView(value: project.viewProgressPercentage)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProjectRowView(project: ProjectModel.mock)
}
