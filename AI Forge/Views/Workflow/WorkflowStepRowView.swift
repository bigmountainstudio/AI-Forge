// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI

struct WorkflowStepRowView: View {
    let step: WorkflowStepModel
    
    var body: some View {
        HStack {
            Image(systemName: step.viewStatusIcon)
                .foregroundStyle(colorForStatus(step.status))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                
                Text(step.stepDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let completedAt = step.completedAt {
                    Text("Completed: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func colorForStatus(_ status: StepStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    WorkflowStepRowView(step: WorkflowStepModel.mock)
}
