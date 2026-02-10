// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

enum SourceFileCategory: String, Codable {
    case apiDocumentation
    case codeExamples
}

struct SourceFileReference: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let filePath: String
    let fileSize: Int64
    let category: SourceFileCategory
    let addedAt: Date
    
    init(fileName: String, filePath: String, fileSize: Int64, category: SourceFileCategory) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.category = category
        self.addedAt = Date()
    }
}

// MARK: - Computed Properties
extension SourceFileReference {
    var viewFileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Preview Helpers
extension SourceFileReference {
    static let mock = SourceFileReference(
        fileName: "API_Documentation.md",
        filePath: "/path/to/API_Documentation.md",
        fileSize: 1024 * 50,
        category: .apiDocumentation
    )
    
    static let mocks = [
        SourceFileReference(
            fileName: "API_Documentation.md",
            filePath: "/path/to/API_Documentation.md",
            fileSize: 1024 * 50,
            category: .apiDocumentation
        ),
        SourceFileReference(
            fileName: "Example.swift",
            filePath: "/path/to/Example.swift",
            fileSize: 1024 * 10,
            category: .codeExamples
        )
    ]
}
