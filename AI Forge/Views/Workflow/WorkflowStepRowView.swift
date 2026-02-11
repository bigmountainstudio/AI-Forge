// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI

struct WorkflowStepRowView: View {
    let step: WorkflowStepModel
    
    var body: some View {
        HStack {
            Image(systemName: step.viewStatusIcon)
                .foregroundStyle(colorForStatus(step.status))
                .accessibilityLabel(statusAccessibilityLabel(step.status))
                .animation(.easeInOut(duration: 0.3), value: step.status)
                .symbolEffect(.bounce, value: step.status == .completed)
            
            VStack(alignment: .leading, spacing: 4) {
                Label("Step \(step.stepNumber)", systemImage: step.icon)
                    .font(.title)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(step.title)
                        .font(.headline)
                }
                
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step.stepNumber): \(step.title)")
        .accessibilityValue(accessibilityValue())
        .accessibilityHint("Double tap to view step details")
    }
    
    private func statusAccessibilityLabel(_ status: StepStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    private func accessibilityValue() -> String {
        var value = statusAccessibilityLabel(step.status)
        if let completedAt = step.completedAt {
            value += ", completed \(completedAt.formatted(date: .abbreviated, time: .shortened))"
        }
        return value
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
