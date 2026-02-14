// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI

struct TrainingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let estimatedTimeRemaining: TimeInterval?
    
    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Training Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentStep) / \(totalSteps)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: progress) {
                HStack {
                    Text(progress, format: .percent.precision(.fractionLength(1)))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    if let timeRemaining = estimatedTimeRemaining {
                        Label(FineTuningConfigurationModel.formatTimeEstimate(timeRemaining), systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
            
            if estimatedTimeRemaining != nil {
                Text("Estimated time remaining based on current training speed")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Training progress: \(currentStep) of \(totalSteps) steps, \(Int(progress * 100)) percent complete")
        .accessibilityValue(estimatedTimeRemaining != nil ? "Estimated time remaining: \(FineTuningConfigurationModel.formatTimeEstimate(estimatedTimeRemaining!))" : "")
    }
}

#Preview("Early Progress") {
    TrainingProgressView(
        currentStep: 50,
        totalSteps: 600,
        estimatedTimeRemaining: 5500
    )
    .padding()
}

#Preview("Mid Progress") {
    TrainingProgressView(
        currentStep: 300,
        totalSteps: 600,
        estimatedTimeRemaining: 2750
    )
    .padding()
}

#Preview("Nearly Complete") {
    TrainingProgressView(
        currentStep: 580,
        totalSteps: 600,
        estimatedTimeRemaining: 100
    )
    .padding()
}

#Preview("No Time Estimate") {
    TrainingProgressView(
        currentStep: 5,
        totalSteps: 600,
        estimatedTimeRemaining: nil
    )
    .padding()
}
