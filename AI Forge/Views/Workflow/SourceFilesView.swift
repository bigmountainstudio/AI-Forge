// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SourceFilesView: View {
    @Bindable var observable: StepDetailObservable
    @State private var showingFilePicker = false
    @State private var selectedPickerCategory: SourceFileCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let errorMessage = observable.errorMessage {
                errorBannerView(message: errorMessage)
            }
            
            if observable.sourceFiles.isEmpty {
                emptyStateView
            } else {
                fileListView
            }
        }
        .animation(.easeInOut, value: observable.sourceFiles.count)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder, .sourceCode, .plainText],
            allowsMultipleSelection: true
        ) { result in
            if let category = selectedPickerCategory {
                handleFileSelection(result, category: category)
            }
        }
    }
    
    private func errorBannerView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error Adding Files")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                }
                
                Spacer()
                
                Button {
                    observable.errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss error")
            }
            .padding(12)
            .background(.red.opacity(0.1), in: .rect(cornerRadius: 8))
            .border(.red.opacity(0.3), width: 1)
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            ContentUnavailableView(
                "No Source Files",
                systemImage: "doc.badge.plus",
                description: Text("Add API documentation and code examples to begin")
            )
            
            HStack(spacing: 12) {
                Button("Add API Docs", systemImage: "doc.text") {
                    selectedPickerCategory = .apiDocumentation
                    showingFilePicker = true
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add API Documentation")
                .accessibilityHint("Opens a file picker to select API documentation files or folders")
                
                Button("Add Examples", systemImage: "chevron.left.forwardslash.chevron.right") {
                    selectedPickerCategory = .codeExamples
                    showingFilePicker = true
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
                Button("Add API Docs", systemImage: "plus") {
                    selectedPickerCategory = .apiDocumentation
                    showingFilePicker = true
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add more API documentation")
                
                Button("Add Examples", systemImage: "plus") {
                    selectedPickerCategory = .codeExamples
                    showingFilePicker = true
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add more code examples")
            }
            .padding(.top, 8)
            
            Divider()
            
            Button("Open Project Folder", systemImage: "folder") {
                openProjectDirectory()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Open project directory in Finder")
            .accessibilityHint("Opens the project folder to view all source files")
        }
    }
    
    private func openProjectDirectory() {
        guard let project = observable.currentProject else { return }
        let projectURL = URL(fileURLWithPath: project.projectDirectoryPath)
        NSWorkspace.shared.open(projectURL)
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
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(directoryPath(for: files.first?.category ?? .apiDocumentation))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help(directoryPathTooltip(for: files.first?.category ?? .apiDocumentation))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: .rect(cornerRadius: 6))
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
                                    .help(directoryPathTooltip(for: file.category))
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
    
    private func directoryPathTooltip(for category: SourceFileCategory) -> String {
        switch category {
        case .apiDocumentation:
            return "API documentation files are stored in the api_training_data directory. This directory contains Swift interface files with API definitions and documentation comments, used by the dataset generation scripts to create training data."
        case .codeExamples:
            return "Code example files are stored in the code_examples directory. This directory contains complete, working SwiftUI examples used by the dataset generation scripts to create training data from practical code patterns."
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

#Preview("No Docs") {
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

#Preview("With Docs") {
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
    
    // Add mock data for preview
    observable.sourceFiles = SourceFileReference.mocks
    
    return SourceFilesView(observable: observable)
        .padding()
}
