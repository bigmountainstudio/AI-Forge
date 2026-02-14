// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData

struct DatasetView: View {
    @Bindable var observable: StepDetailObservable
    
    @State private var expandedRows: Set<Int> = []
    @State private var searchText = ""
    
    var filteredEntries: [[String: String]] {
        if searchText.isEmpty {
            return observable.datasetEntries
        }
        
        return observable.datasetEntries.filter { entry in
            let instruction = entry["instruction"] ?? ""
            let output = entry["output"] ?? ""
            return instruction.localizedCaseInsensitiveContains(searchText) ||
                   output.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if observable.isLoadingDataset {
                VStack {
                    ProgressView("Loading dataset...")
                        .progressViewStyle(.circular)
                    Text("Parsing JSONL file contents")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Dataset Statistics
                    if let stats = observable.datasetStatistics {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dataset Statistics")
                                    .font(.headline)
                                
                                HStack(spacing: 24) {
                                    StatItem(label: "Total Examples", value: "\(stats.total)")
                                    StatItem(label: "File Size", value: stats.fileSize)
                                }
                            }
                            .padding()
                            .background(.regularMaterial, in: .rect(cornerRadius: 8))
                            
                            Spacer()
                            
                            Button("Open Dataset Folder", systemImage: "folder") {
                                guard let project = observable.currentProject else { return }
                                let dataFolderURL = URL(fileURLWithPath: project.projectDirectoryPath).appendingPathComponent("data")
                                NSWorkspace.shared.open(dataFolderURL)
                            }
                        }
                    }
                    
                    // Search Bar
                    if observable.datasetEntries.isEmpty == false {
                        TextField("Search examples...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Search dataset")
                            .accessibilityHint("Filter examples by instruction or output content")
                    }
                    
                    // Dataset Entries List
                    if observable.datasetEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("No dataset found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Execute this step to generate the optimized dataset")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredEntries.enumerated()), id: \.offset) { index, entry in
                                    DatasetEntryRow(
                                        entry: entry,
                                        index: index,
                                        isExpanded: expandedRows.contains(index)
                                    ) {
                                        toggleExpansion(for: index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func toggleExpansion(for index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedRows.contains(index) {
                expandedRows.remove(index)
            } else {
                expandedRows.insert(index)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

struct DatasetEntryRow: View {
    let entry: [String: String]
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with instruction
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Example \(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(entry["instruction"] ?? "")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // Expanded content
            if isExpanded {
                Divider()
                
                // Input (if present)
                if let input = entry["input"], input.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Input")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(input)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
                
                // Output
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollView {
                        Text(entry["output"] ?? "")
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                    .background(.regularMaterial, in: .rect(cornerRadius: 4))
                }
            }
        }
        .padding()
        .background(isExpanded ? Color.accentColor.opacity(0.05) : Color.clear, in: .rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview("With No Data") {
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    let workflowEngine = WorkflowEngineObservable(
        modelContext: ProjectModel.preview.mainContext,
        pythonExecutor: pythonExecutor,
        fileSystemManager: fileSystemManager
    )
    
    let observable = StepDetailObservable(
        workflowEngine: workflowEngine,
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    
    // No data added - should show empty state
    observable.datasetEntries = []
    observable.datasetStatistics = nil
    
    return DatasetView(observable: observable)
}

#Preview("With Data") {
    let fileSystemManager = FileSystemManager()
    let pythonExecutor = PythonScriptExecutor()
    let workflowEngine = WorkflowEngineObservable(
        modelContext: ProjectModel.preview.mainContext,
        pythonExecutor: pythonExecutor,
        fileSystemManager: fileSystemManager
    )
    
    let observable = StepDetailObservable(
        workflowEngine: workflowEngine,
        fileSystemManager: fileSystemManager,
        pythonExecutor: pythonExecutor
    )
    
    // Add sample data
    observable.datasetEntries = [
        [
            "instruction": "Show me how to implement a button in SwiftUI.",
            "input": "",
            "output": "```swift\nButton(\"Click Me\") {\n    print(\"Button tapped\")\n}\n```"
        ],
        [
            "instruction": "How do I create a list in SwiftUI?",
            "input": "",
            "output": "Here's an example of a list in SwiftUI:\n\n```swift\nList {\n    Text(\"Item 1\")\n    Text(\"Item 2\")\n    Text(\"Item 3\")\n}\n```"
        ]
    ]
    observable.datasetStatistics = (total: 2, fileSize: "1.2 KB")
    
    return DatasetView(observable: observable)
}
