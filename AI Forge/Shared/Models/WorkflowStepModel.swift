// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftData
import Foundation

enum StepStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

@Model
final class WorkflowStepModel {
    var stepNumber: Int
    var title: String
    var stepDescription: String
    var icon: String
    var status: StepStatus
    var completedAt: Date?
    var errorMessage: String?
    
    init(stepNumber: Int, title: String, stepDescription: String, icon: String) {
        self.stepNumber = stepNumber
        self.title = title
        self.stepDescription = stepDescription
        self.icon = icon
        self.status = .pending
    }
    
    static func createDefaultSteps() -> [WorkflowStepModel] {
        return [
            WorkflowStepModel(
                stepNumber: 1,
                title: "Prepare Source Files",
                stepDescription: "Place source files in appropriate directories",
                icon: "document.badge.plus.fill"
            ),
            WorkflowStepModel(
                stepNumber: 2,
                title: "Generate Optimized Dataset",
                stepDescription: "Run script to parse files and create training data",
                icon: "chart.bar.doc.horizontal.fill"
            ),
            WorkflowStepModel(
                stepNumber: 3,
                title: "Configure Fine-Tuning",
                stepDescription: "Update configuration with model settings",
                icon: "slider.horizontal.3"
            ),
            WorkflowStepModel(
                stepNumber: 4,
                title: "Run Fine-Tuning",
                stepDescription: "Execute the fine-tuning process",
                icon: "flame.fill"
            ),
            WorkflowStepModel(
                stepNumber: 5,
                title: "Evaluate for Overfitting",
                stepDescription: "Test model on held-out test data",
                icon: "magnifyingglass.circle.fill"
            ),
            WorkflowStepModel(
                stepNumber: 6,
                title: "Convert and Deploy",
                stepDescription: "Convert model for inference",
                icon: "shippingbox.fill"
            )
        ]
    }
}

// MARK: - Computed Properties
extension WorkflowStepModel {
    var viewStatusIcon: String {
        switch status {
        case .pending: return "circle"
        case .inProgress: return "arrow.clockwise.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var viewStatusColor: String {
        switch status {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}

// MARK: - Preview Helpers
extension WorkflowStepModel {
    static let mock = WorkflowStepModel(
        stepNumber: 1,
        title: "Prepare Source Files",
        stepDescription: "Place source files in appropriate directories",
        icon: "doc.text.fill"
    )
}
