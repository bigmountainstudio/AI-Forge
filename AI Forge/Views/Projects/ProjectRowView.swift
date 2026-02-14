// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI

struct ProjectRowView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            
            Text(project.customizationDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("Step \(project.currentStepIndex + 1) of 6")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                ProgressView(value: project.viewProgressPercentage)
                    .accessibilityLabel("Project progress")
                    .accessibilityValue("\(Int(project.viewProgressPercentage * 100)) percent complete")
                    .animation(.easeInOut, value: project.viewProgressPercentage)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name), \(project.customizationDescription)")
        .accessibilityValue("Step \(project.currentStepIndex + 1) of 6, \(Int(project.viewProgressPercentage * 100)) percent complete")
    }
}

#Preview {
    ProjectRowView(project: ProjectModel.mock)
}
