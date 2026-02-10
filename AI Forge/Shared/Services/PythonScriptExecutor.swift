// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

actor PythonScriptExecutor {
    private var currentProcess: Process?
    
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
        
        // Configure process
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath] + arguments
        
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
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
