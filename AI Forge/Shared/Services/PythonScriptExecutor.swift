// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

actor PythonScriptExecutor {
    private var currentProcess: Process?
    
    // MARK: - Python Executable Resolution
    
    /// Searches a directory for a Python virtual environment and returns the python executable if found
    private func findVenvPython(in directory: URL) -> URL? {
        let candidates = [
            directory.appendingPathComponent(".venv/bin/python3"),
            directory.appendingPathComponent(".venv/bin/python"),
            directory.appendingPathComponent("venv/bin/python3"),
            directory.appendingPathComponent("venv/bin/python"),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
    
    /// Searches up the directory tree from a starting URL for a virtual environment
    private func searchUpForVenv(from startURL: URL, maxLevels: Int = 6) -> URL? {
        var searchURL = startURL
        for _ in 0..<maxLevels {
            if let python = findVenvPython(in: searchURL) {
                return python
            }
            let parent = searchURL.deletingLastPathComponent()
            if parent.path == searchURL.path { break }
            searchURL = parent
        }
        return nil
    }
    
    /// Finds the appropriate Python executable, preferring a virtual environment with ML packages installed.
    ///
    /// Search order:
    /// 1. Virtual environment in working directory
    /// 2. Virtual environment near the script being executed (walks up from script path)
    /// 3. Virtual environment near the Swift source file (compile-time #filePath, development builds only)
    /// 4. Virtual environment in current process directory
    /// 5. Virtual environment near Bundle.main.resourcePath (walks up)
    /// 6. Homebrew Python (/opt/homebrew or /usr/local)
    /// 7. System Python (/usr/bin/python3) — last resort
    private func findPythonExecutable(workingDirectory: String?,
                                      scriptPath: String? = nil,
                                      sourceFile: String = #filePath) -> URL {
        // 1. Check for virtual environment in the working directory
        if let workDir = workingDirectory {
            if let python = findVenvPython(in: URL(fileURLWithPath: workDir)) {
                return python
            }
        }
        
        // 2. Search up from the script path — handles development environment where
        //    the script lives inside the source tree alongside the .venv
        if let scriptPath = scriptPath {
            let scriptDirURL = URL(fileURLWithPath: scriptPath).deletingLastPathComponent()
            if let python = searchUpForVenv(from: scriptDirURL) {
                return python
            }
        }
        
        // 3. Search up from the Swift source file location (development builds only).
        //    #filePath resolves at compile time to the absolute path of this .swift file,
        //    e.g. /Users/mark/Documents/GitHub/AI Forge/AI Forge/Shared/Services/PythonScriptExecutor.swift
        //    Walking up from there reaches the workspace root where .venv lives.
        let sourceFileURL = URL(fileURLWithPath: sourceFile).deletingLastPathComponent()
        if let python = searchUpForVenv(from: sourceFileURL) {
            return python
        }
        
        // 4. Check for virtual environment in current process directory
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let python = findVenvPython(in: currentDir) {
            return python
        }
        
        // 5. Search up from Bundle resources (useful for archived/release builds)
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            if let python = searchUpForVenv(from: resourceURL, maxLevels: 8) {
                return python
            }
        }
        
        // 6. Try Homebrew Python (Apple Silicon, then Intel)
        let homebrewPaths = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3"
        ]
        for path in homebrewPaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // 7. Final fallback: system Python
        // Note: On macOS this often resolves to Xcode's CommandLineTools Python
        // which may not have ML packages (mlx, mlx-lm) installed.
        return URL(fileURLWithPath: "/usr/bin/python3")
    }
    
    // MARK: - Script Execution
    
    /// Executes a Python script with the given parameters
    /// - Parameters:
    ///   - scriptPath: Path to the Python script to execute
    ///   - arguments: Command-line arguments to pass to the script
    ///   - workingDirectory: Working directory for script execution
    ///   - outputHandler: Closure called with output as it's received
    /// - Returns: ScriptExecutionResult containing exit code, output, and error information
    func executeScript(
        scriptPath: String,
        arguments: [String] = [],
        workingDirectory: String? = nil,
        outputHandler: ((String) -> Void)? = nil
    ) async throws -> ScriptExecutionResult {
        // Create process
        let process = Process()
        currentProcess = process
        
        // Find Python executable, using script path as a search hint
        let pythonExecutableURL = findPythonExecutable(
            workingDirectory: workingDirectory,
            scriptPath: scriptPath
        )
        
        // Determine how to run the script based on extension
        let isPythonScript = scriptPath.lowercased().hasSuffix(".py")
        let isShellScript = scriptPath.lowercased().hasSuffix(".sh")
        
        if isPythonScript {
            process.executableURL = pythonExecutableURL
            process.arguments = [scriptPath] + arguments
        } else if isShellScript {
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [scriptPath] + arguments
        } else {
            // Assume it's an executable
            process.executableURL = URL(fileURLWithPath: scriptPath)
            process.arguments = arguments
        }
        
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        // Set environment variables to include common binary paths and current Python path
        var environment = ProcessInfo.processInfo.environment
        
        // Add Python's bin directory to PATH to ensure subprocesses use the same environment
        let pythonBinPath = pythonExecutableURL.deletingLastPathComponent().path
        let commonPaths = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        
        if let existingPath = environment["PATH"] {
            // Prepend Python bin path and common locations to existing PATH
            environment["PATH"] = "\(pythonBinPath):\(commonPaths):\(existingPath)"
        } else {
            environment["PATH"] = "\(pythonBinPath):\(commonPaths)"
        }
        
        // Ensure scripts don't inherit problematic Python environment from parent app
        environment["PYTHONUNBUFFERED"] = "1"
        
        // If we found a virtual environment, clear PYTHONHOME/PYTHONPATH to ensure isolation
        if pythonExecutableURL.path.contains(".venv") || pythonExecutableURL.path.contains("/venv/") {
            environment.removeValue(forKey: "PYTHONHOME")
            environment.removeValue(forKey: "PYTHONPATH")
        }
        
        process.environment = environment
        
        // Create pipes for stdout and stderr
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        var outputData = Data()
        var errorData = Data()
        
        // Serial queue to synchronize access to outputData and errorData
        let dataQueue = DispatchQueue(label: "com.bigmountainstudio.pythonExecutor.dataQueue")
        
        // Set up readability handlers for real-time output capture
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty == false {
                dataQueue.async {
                    outputData.append(data)
                    if let output = String(data: data, encoding: .utf8), let handler = outputHandler {
                        handler(output)
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty == false {
                dataQueue.async {
                    errorData.append(data)
                    if let output = String(data: data, encoding: .utf8), let handler = outputHandler {
                        handler(output)
                    }
                }
            }
        }
        
        // Launch process
        try process.run()
        
        // Wait for completion
        process.waitUntilExit()
        
        // Clean up handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        // Get exit code
        let exitCode = Int(process.terminationStatus)
        
        // Convert output to strings
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        
        // Clear current process
        currentProcess = nil
        
        return ScriptExecutionResult(
            exitCode: exitCode,
            output: output,
            error: error,
            success: exitCode == 0
        )
    }
    
    // MARK: - Process Control
    
    /// Cancels the currently executing script
    func cancelExecution() async {
        guard let process = currentProcess, process.isRunning else {
            return
        }
        
        process.terminate()
        currentProcess = nil
    }
    
    // MARK: - Python Verification
    
    /// Verifies that Python 3 is installed and accessible
    /// - Returns: True if Python 3 is available, false otherwise
    func verifyPythonInstallation() async -> Bool {
        let pythonURL = findPythonExecutable(workingDirectory: nil)
        let process = Process()
        process.executableURL = pythonURL
        process.arguments = ["--version"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

// MARK: - Result Types

struct ScriptExecutionResult {
    let exitCode: Int
    let output: String
    let error: String
    let success: Bool
}
