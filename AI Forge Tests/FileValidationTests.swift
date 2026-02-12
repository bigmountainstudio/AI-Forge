// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import XCTest
import Foundation
@testable import AI_Forge

/// Unit tests for file validation and error handling in FileSystemManager
final class FileValidationTests: XCTestCase {
    
    var fileSystemManager: FileSystemManager!
    var testDirectory: URL!
    
    override func setUp() {
        super.setUp()
        fileSystemManager = FileSystemManager()
        
        // Create a temporary test directory
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "FileValidationTests_\(UUID().uuidString)",
            isDirectory: true
        )
        
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up test directory
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - File Extension Validation Tests
    
    func testValidSwiftFileExtension() {
        let swiftFileURL = testDirectory.appendingPathComponent("test.swift")
        FileManager.default.createFile(atPath: swiftFileURL.path, contents: nil)
        
        let isValid = fileSystemManager.isValidSwiftFile(swiftFileURL)
        XCTAssertTrue(isValid, "Should recognize .swift file as valid")
    }
    
    func testInvalidFileExtension() {
        let invalidFileURL = testDirectory.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: invalidFileURL.path, contents: nil)
        
        let isValid = fileSystemManager.isValidSwiftFile(invalidFileURL)
        XCTAssertFalse(isValid, "Should reject .txt file")
    }
    
    func testInvalidFileExtensionMarkdown() {
        let mdFileURL = testDirectory.appendingPathComponent("README.md")
        FileManager.default.createFile(atPath: mdFileURL.path, contents: nil)
        
        let isValid = fileSystemManager.isValidSwiftFile(mdFileURL)
        XCTAssertFalse(isValid, "Should reject .md file")
    }
    
    func testFileWithoutExtension() {
        let noExtFileURL = testDirectory.appendingPathComponent("Makefile")
        FileManager.default.createFile(atPath: noExtFileURL.path, contents: nil)
        
        let isValid = fileSystemManager.isValidSwiftFile(noExtFileURL)
        XCTAssertFalse(isValid, "Should reject file without extension")
    }
    
    func testCaseInsensitiveSwiftExtension() {
        let swiftFileURL = testDirectory.appendingPathComponent("test.SWIFT")
        FileManager.default.createFile(atPath: swiftFileURL.path, contents: nil)
        
        let isValid = fileSystemManager.isValidSwiftFile(swiftFileURL)
        XCTAssertTrue(isValid, "Should recognize .SWIFT (uppercase) as valid")
    }
    
    // MARK: - Folder Validation Tests
    
    func testValidFolderValidation() throws {
        let folderURL = testDirectory.appendingPathComponent("ValidFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        // Should not throw
        try fileSystemManager.validateFolder(folderURL)
    }
    
    func testNonexistentFolderValidation() {
        let nonexistentURL = testDirectory.appendingPathComponent("NonexistentFolder", isDirectory: true)
        
        XCTAssertThrowsError(try fileSystemManager.validateFolder(nonexistentURL)) { error in
            XCTAssertTrue(error is FileSystemError)
            if let fsError = error as? FileSystemError {
                if case .directoryNotFound = fsError {
                    // Expected error
                } else {
                    XCTFail("Expected directoryNotFound error, got \(fsError)")
                }
            }
        }
    }
    
    func testFileAsDirectoryValidation() throws {
        let fileURL = testDirectory.appendingPathComponent("notADirectory.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        
        XCTAssertThrowsError(try fileSystemManager.validateFolder(fileURL)) { error in
            XCTAssertTrue(error is FileSystemError)
            if let fsError = error as? FileSystemError {
                if case .notADirectory = fsError {
                    // Expected error
                } else {
                    XCTFail("Expected notADirectory error, got \(fsError)")
                }
            }
        }
    }
    
    // MARK: - File or Folder Validation Tests
    
    func testValidateValidSwiftFile() {
        let swiftFileURL = testDirectory.appendingPathComponent("valid.swift")
        FileManager.default.createFile(atPath: swiftFileURL.path, contents: nil)
        
        let result = fileSystemManager.validateFileOrFolder(swiftFileURL)
        
        XCTAssertTrue(result.isValid, "Should validate valid .swift file")
        XCTAssertEqual(result.fileName, "valid.swift")
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateInvalidFileExtension() {
        let invalidFileURL = testDirectory.appendingPathComponent("invalid.txt")
        FileManager.default.createFile(atPath: invalidFileURL.path, contents: nil)
        
        let result = fileSystemManager.validateFileOrFolder(invalidFileURL)
        
        XCTAssertFalse(result.isValid, "Should reject invalid file type")
        XCTAssertEqual(result.fileName, "invalid.txt")
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains(".txt") ?? false, "Error should mention file extension")
        XCTAssertTrue(result.errorMessage?.contains("invalid.txt") ?? false, "Error should mention file name")
    }
    
    func testValidateNonexistentFile() {
        let nonexistentURL = testDirectory.appendingPathComponent("nonexistent.swift")
        
        let result = fileSystemManager.validateFileOrFolder(nonexistentURL)
        
        XCTAssertFalse(result.isValid, "Should reject nonexistent file")
        XCTAssertEqual(result.fileName, "nonexistent.swift")
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("not found") ?? false, "Error should mention file not found")
    }
    
    func testValidateValidFolder() throws {
        let folderURL = testDirectory.appendingPathComponent("ValidFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let result = fileSystemManager.validateFileOrFolder(folderURL)
        
        XCTAssertTrue(result.isValid, "Should validate valid folder")
        XCTAssertEqual(result.fileName, "ValidFolder")
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateInaccessibleFolder() {
        let folderURL = testDirectory.appendingPathComponent("InaccessibleFolder", isDirectory: true)
        
        let result = fileSystemManager.validateFileOrFolder(folderURL)
        
        // On macOS, a nonexistent folder is reported as not found, not as inaccessible
        XCTAssertFalse(result.isValid, "Should reject nonexistent folder")
        XCTAssertEqual(result.fileName, "InaccessibleFolder")
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("not found") ?? result.errorMessage?.contains("Cannot access") ?? false, 
                     "Error should mention folder not found or access issue")
    }
    
    // MARK: - Error Message Specificity Tests
    
    func testErrorMessageIncludesFileName() {
        let invalidFileURL = testDirectory.appendingPathComponent("MySpecialFile.json")
        FileManager.default.createFile(atPath: invalidFileURL.path, contents: nil)
        
        let result = fileSystemManager.validateFileOrFolder(invalidFileURL)
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("MySpecialFile.json") ?? false,
                     "Error message should include the specific file name")
    }
    
    func testErrorMessageIncludesFileExtension() {
        let invalidFileURL = testDirectory.appendingPathComponent("document.pdf")
        FileManager.default.createFile(atPath: invalidFileURL.path, contents: nil)
        
        let result = fileSystemManager.validateFileOrFolder(invalidFileURL)
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains(".pdf") ?? false,
                     "Error message should include the file extension")
    }
    
    func testErrorMessageIncludesFolderName() {
        let folderURL = testDirectory.appendingPathComponent("MyFolder", isDirectory: true)
        
        let result = fileSystemManager.validateFileOrFolder(folderURL)
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("MyFolder") ?? false,
                     "Error message should include the folder name")
    }
    
    // MARK: - Recursive Swift File Discovery Tests
    
    func testFindSwiftFilesInFlatDirectory() throws {
        let folderURL = testDirectory.appendingPathComponent("FlatFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        // Create test files
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent("file1.swift").path, contents: nil)
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent("file2.swift").path, contents: nil)
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent("file3.txt").path, contents: nil)
        
        let swiftFiles = try fileSystemManager.findSwiftFiles(in: folderURL)
        
        XCTAssertEqual(swiftFiles.count, 2, "Should find exactly 2 .swift files")
        XCTAssertTrue(swiftFiles.allSatisfy { $0.pathExtension == "swift" }, "All found files should be .swift")
    }
    
    func testFindSwiftFilesInNestedDirectories() throws {
        let folderURL = testDirectory.appendingPathComponent("NestedFolder", isDirectory: true)
        let subfolderURL = folderURL.appendingPathComponent("subfolder", isDirectory: true)
        let deeperFolderURL = subfolderURL.appendingPathComponent("deeper", isDirectory: true)
        
        try FileManager.default.createDirectory(at: deeperFolderURL, withIntermediateDirectories: true)
        
        // Create test files at different levels
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent("root.swift").path, contents: nil)
        FileManager.default.createFile(atPath: subfolderURL.appendingPathComponent("sub.swift").path, contents: nil)
        FileManager.default.createFile(atPath: deeperFolderURL.appendingPathComponent("deep.swift").path, contents: nil)
        
        let swiftFiles = try fileSystemManager.findSwiftFiles(in: folderURL)
        
        XCTAssertEqual(swiftFiles.count, 3, "Should find .swift files in all nested directories")
    }
    
    func testFindSwiftFilesEmptyFolder() throws {
        let folderURL = testDirectory.appendingPathComponent("EmptyFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let swiftFiles = try fileSystemManager.findSwiftFiles(in: folderURL)
        
        XCTAssertEqual(swiftFiles.count, 0, "Should return empty array for folder with no .swift files")
    }
    
    func testFindSwiftFilesNonexistentFolder() {
        let nonexistentURL = testDirectory.appendingPathComponent("NonexistentFolder", isDirectory: true)
        
        XCTAssertThrowsError(try fileSystemManager.findSwiftFiles(in: nonexistentURL)) { error in
            XCTAssertTrue(error is FileSystemError)
        }
    }
    
    func testFindSwiftFilesIgnoresHiddenFiles() throws {
        let folderURL = testDirectory.appendingPathComponent("HiddenFilesFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        // Create visible and hidden files
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent("visible.swift").path, contents: nil)
        FileManager.default.createFile(atPath: folderURL.appendingPathComponent(".hidden.swift").path, contents: nil)
        
        let swiftFiles = try fileSystemManager.findSwiftFiles(in: folderURL)
        
        XCTAssertEqual(swiftFiles.count, 1, "Should ignore hidden .swift files")
        XCTAssertTrue(swiftFiles[0].lastPathComponent == "visible.swift")
    }
    
    // MARK: - FileSystemError Tests
    
    func testFileSystemErrorDescriptions() {
        let fileNotFoundError = FileSystemError.fileNotFound("/path/to/file")
        XCTAssertNotNil(fileNotFoundError.errorDescription)
        XCTAssertTrue(fileNotFoundError.errorDescription?.contains("/path/to/file") ?? false)
        
        let invalidExtError = FileSystemError.invalidFileExtension("test.txt", ".txt")
        XCTAssertNotNil(invalidExtError.errorDescription)
        XCTAssertTrue(invalidExtError.errorDescription?.contains("test.txt") ?? false)
        XCTAssertTrue(invalidExtError.errorDescription?.contains(".txt") ?? false)
        
        let noSwiftFilesError = FileSystemError.noSwiftFilesInFolder("MyFolder")
        XCTAssertNotNil(noSwiftFilesError.errorDescription)
        XCTAssertTrue(noSwiftFilesError.errorDescription?.contains("MyFolder") ?? false)
    }
}
