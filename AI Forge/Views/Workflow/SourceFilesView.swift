// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SourceFilesView: View {
    @Bindable var observable: StepDetailObservable
    @State private var showingAPIDocumentationPicker = false
    @State private var showingCodeExamplesPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            helpSection
            
            if observable.sourceFiles.isEmpty {
                emptyStateView
            } else {
                fileListView
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: observable.sourceFiles.count)
        .fileImporter(
            isPresented: $showingAPIDocumentationPicker,
            allowedContentTypes: [.folder, .sourceCode, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result, category: .apiDocumentation)
        }
        .fileImporter(
            isPresented: $showingCodeExamplesPicker,
            allowedContentTypes: [.folder, .sourceCode, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result, category: .codeExamples)
        }
    }
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source Files")
                .font(.headline)
            
            Text("Add API documentation and code examples to generate training data. You can select individual files or entire folders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("API Documentation", systemImage: "doc.text")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Swift interface files with API definitions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Code Examples", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Complete working SwiftUI examples")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)
            
            Text("No Source Files")
                .font(.headline)
            
            Text("Add API documentation and code examples to begin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button {
                    showingAPIDocumentationPicker = true
                } label: {
                    Label("Add API Docs", systemImage: "doc.text.plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add API Documentation")
                .accessibilityHint("Opens a file picker to select API documentation files or folders")
                
                Button {
                    showingCodeExamplesPicker = true
                } label: {
                    Label("Add Examples", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add Code Examples")
                .accessibilityHint("Opens a file picker to select code example files or folders")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .transition(.opacity.combined(with: .scale))
    }
    
    private var fileListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            let apiDocs = observable.sourceFiles.filter { $0.category == .apiDocumentation }
            let codeExamples = observable.sourceFiles.filter { $0.category == .codeExamples }
            
            if apiDocs.isEmpty == false {
                categorySection(title: "API Documentation", files: apiDocs, icon: "doc.text")
            }
            
            if codeExamples.isEmpty == false {
                categorySection(title: "Code Examples", files: codeExamples, icon: "chevron.left.forwardslash.chevron.right")
            }
            
            HStack(spacing: 12) {
                Button {
                    showingAPIDocumentationPicker = true
                } label: {
                    Label("Add API Docs", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add more API documentation")
                
                Button {
                    showingCodeExamplesPicker = true
                } label: {
                    Label("Add Examples", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add more code examples")
            }
            .padding(.top, 8)
        }
    }
    
    private func categorySection(title: String, files: [SourceFileReference], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(files.count) file\(files.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            List {
                ForEach(files) { file in
                    HStack {
                        Image(systemName: icon)
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
                                
                                Text(directoryPath(for: file.category))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await observable.removeSourceFile(file)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete \(file.fileName)")
                        .accessibilityHint("Removes this file from the project")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await observable.removeSourceFile(file)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(minHeight: 100)
        }
    }
    
    private func directoryPath(for category: SourceFileCategory) -> String {
        switch category {
        case .apiDocumentation: return "../api_training_data/"
        case .codeExamples: return "code_examples/"
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>, category: SourceFileCategory) {
        switch result {
        case .success(let urls):
            Task {
                await observable.addSourceFilesOrFolders(urls, category: category)
            }
        case .failure(let error):
            observable.errorMessage = "Failed to select files: \(error.localizedDescription)"
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
