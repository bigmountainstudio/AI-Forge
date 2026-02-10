// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import Foundation

/// Error logging infrastructure for AI Forge
final class ErrorLogger {
    
    // MARK: - Severity Levels
    
    enum Severity: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    // MARK: - Log Categories
    
    enum Category: String {
        case project = "Project"
        case workflow = "Workflow"
        case fileSystem = "FileSystem"
        case pythonScript = "PythonScript"
        case database = "Database"
        case general = "General"
    }
    
    // MARK: - Properties
    
    private static let shared = ErrorLogger()
    private let logDirectory: URL
    private let dateFormatter: DateFormatter
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {
        // Create log directory: ~/Library/Logs/AIForge/
        let logsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")
            .appendingPathComponent("AIForge")
        
        self.logDirectory = logsURL
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // Configure date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    // MARK: - Public Logging Methods
    
    /// Log a message with specified severity and category
    /// - Parameters:
    ///   - message: The message to log
    ///   - severity: The severity level of the log
    ///   - category: The category of the log
    ///   - file: The source file (automatically captured)
    ///   - function: The function name (automatically captured)
    ///   - line: The line number (automatically captured)
    static func log(
        _ message: String,
        severity: Severity = .info,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.writeLog(
            message: message,
            severity: severity,
            category: category,
            file: file,
            function: function,
            line: line,
            error: nil
        )
    }
    
    /// Log an error with full details including stack trace
    /// - Parameters:
    ///   - error: The error to log
    ///   - message: Additional context message
    ///   - category: The category of the log
    ///   - file: The source file (automatically captured)
    ///   - function: The function name (automatically captured)
    ///   - line: The line number (automatically captured)
    static func logError(
        _ error: Error,
        message: String? = nil,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorMessage = message ?? "An error occurred"
        shared.writeLog(
            message: errorMessage,
            severity: .error,
            category: category,
            file: file,
            function: function,
            line: line,
            error: error
        )
    }
    
    /// Log a critical error with full details
    /// - Parameters:
    ///   - error: The error to log
    ///   - message: Additional context message
    ///   - category: The category of the log
    ///   - file: The source file (automatically captured)
    ///   - function: The function name (automatically captured)
    ///   - line: The line number (automatically captured)
    static func logCritical(
        _ error: Error,
        message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.writeLog(
            message: message,
            severity: .critical,
            category: category,
            file: file,
            function: function,
            line: line,
            error: error
        )
    }
    
    // MARK: - Private Methods
    
    private func writeLog(
        message: String,
        severity: Severity,
        category: Category,
        file: String,
        function: String,
        line: Int,
        error: Error?
    ) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        
        // Build log entry
        var logEntry = "[\(timestamp)] [\(severity.rawValue)] [\(category.rawValue)] \(message)\n"
        logEntry += "  Location: \(fileName):\(line) - \(function)\n"
        
        // Add error details if present
        if let error = error {
            logEntry += "  Error: \(error.localizedDescription)\n"
            logEntry += "  Error Type: \(type(of: error))\n"
            
            // Add underlying error if available
            if let nsError = error as NSError? {
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                    logEntry += "  Underlying Error: \(underlyingError.localizedDescription)\n"
                }
                
                // Add additional user info
                if nsError.userInfo.isEmpty == false {
                    logEntry += "  Additional Info: \(nsError.userInfo)\n"
                }
            }
        }
        
        logEntry += "\n"
        
        // Write to log file
        writeToFile(logEntry, category: category)
        
        // Also print to console for debugging
        #if DEBUG
        print(logEntry)
        #endif
    }
    
    private func writeToFile(_ entry: String, category: Category) {
        // Create log file name based on current date and category
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        let logFileName = "aiforge_\(category.rawValue.lowercased())_\(dateString).log"
        let logFileURL = logDirectory.appendingPathComponent(logFileName)
        
        // Append to log file
        if let data = entry.data(using: .utf8) {
            if fileManager.fileExists(atPath: logFileURL.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // Create new file
                try? data.write(to: logFileURL)
            }
        }
    }
}
