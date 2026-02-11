# AI Forge Integration Tests

This directory contains integration tests for the AI Forge application.

## Test Files

### ConfigurationManagementIntegrationTests.swift
Integration tests for configuration management workflow covering:
- Configuration creation and attachment to projects
- Configuration modification and persistence
- Configuration validation (model name, learning rate, batch size, epochs)
- Configuration persistence across context saves
- Configuration cascade deletion with projects
- Script execution integration with configuration values
- Configuration updates through observables
- Complete configuration workflow (create → validate → save → load)

## Running the Tests

### Option 1: Add Test Target to Xcode Project

1. Open `AI Forge.xcodeproj` in Xcode
2. Go to File → New → Target
3. Select "Unit Testing Bundle" for macOS
4. Name it "AI Forge Tests"
5. Add the test files from the "AI Forge Tests" directory to the test target
6. Run tests with Cmd+U or Product → Test

### Option 2: Run Tests via xcodebuild (Command Line)

Once the test target is added to the project:

```bash
xcodebuild test -project "AI Forge.xcodeproj" -scheme "AI Forge" -destination 'platform=macOS'
```

### Option 3: Manual Verification

Since the tests use in-memory SwiftData containers and don't require external dependencies, you can verify the implementation by:

1. Building the main app to ensure all models and observables compile
2. Reviewing the test code to verify it covers all requirements
3. Running the app and manually testing configuration workflows

## Test Coverage

The integration tests cover the following requirements from the design document:

- **Requirement 6.1**: Configuration display and editing
- **Requirement 6.2**: Configuration parameter fields
- **Requirement 6.3**: Configuration validation
- **Requirement 6.4**: Configuration persistence to file
- **Requirement 6.5**: Configuration loading from saved state
- **Requirement 6.6**: Configuration save marks step complete

## Test Structure

All tests use:
- In-memory SwiftData containers for isolation
- `@MainActor` for SwiftData operations
- XCTest framework for assertions
- Async/await patterns for observable operations
- Expectations for async test verification

## Notes

- Tests are designed to run independently without side effects
- No external files or databases are modified
- All test data is created in-memory and cleaned up automatically
- Tests verify both model-level and observable-level functionality
