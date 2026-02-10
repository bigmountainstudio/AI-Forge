// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SourceFilesView: View {
    @Bindable var observable: StepDetailObservable
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if observable.sourceFiles.isEmpty {
                emptyStateView
            } else {
                fileListView
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.text, .plainText, .sourceCode, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await observable.addSourceFiles(urls)
                }
            case .failure(let error):
                observable.errorMessage = "Failed to select files: \(error.localizedDescription)"
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Source Files")
                .font(.headline)
            
            Text("Add API documentation and code examples to begin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingFilePicker = true
            } label: {
                Label("Add Files", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var fileListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Source Files")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Add Files", systemImage: "plus")
                }
            }
            
            List {
                ForEach(observable.sourceFiles) { file in
                    HStack {
                        Image(systemName: iconForCategory(file.category))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.fileName)
                                .font(.body)
                            
                            HStack {
                                Text(file.viewFileSizeFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("•")
                                    .foregroundStyle(.secondary)
                                
                                Text(categoryLabel(file.category))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await observable.removeSourceFile(file)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .frame(minHeight: 200)
        }
    }
    
    private func iconForCategory(_ category: SourceFileCategory) -> String {
        switch category {
        case .apiDocumentation: return "doc.text"
        case .codeExamples: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    private func categoryLabel(_ category: SourceFileCategory) -> String {
        switch category {
        case .apiDocumentation: return "API Documentation"
        case .codeExamples: return "Code Examples"
        }
    }
}

#Preview {
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
    
    SourceFilesView(observable: observable)
}
