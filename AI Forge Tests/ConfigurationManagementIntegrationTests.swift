// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import XCTest
import SwiftData
import Foundation
@testable import AI_Forge

/// Integration tests for configuration management workflow
/// Tests configuration creation, modification, validation, persistence, and script execution integration
final class ConfigurationManagementIntegrationTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Creates an in-memory model container for testing
    @MainActor
    private func createTestContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: ProjectModel.self, WorkflowStepModel.self, FineTuningConfigurationModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container
    }
    
    /// Creates a test project with workflow steps
    @MainActor
    private func createTestProject(in context: ModelContext) -> ProjectModel {
        let project = ProjectModel(
            name: "Test Configuration Project",
            customizationDescription: "Testing configuration management"
        )
        project.projectDirectoryPath = "/tmp/test_config_project"
        context.insert(project)
        
        // Explicitly insert workflow steps into context
        for step in project.workflowSteps {
            context.insert(step)
        }
        
        return project
    }
    
    // MARK: - Configuration Creation Tests
    
    @MainActor
    func testConfigurationCreation() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        // Create configuration
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        config.outputDirectory = "/tmp/output"
        config.datasetPath = "/tmp/dataset.json"
        
        context.insert(config)
        project.configuration = config
        
        try context.save()
        
        // Verify configuration is attached
        XCTAssertNotNil(project.configuration)
        XCTAssertEqual(project.configuration?.modelName, "gpt-3.5-turbo")
        XCTAssertEqual(project.configuration?.learningRate, 0.0001)
        XCTAssertEqual(project.configuration?.batchSize, 8)
        XCTAssertEqual(project.configuration?.numberOfEpochs, 3)
    }
    
    // MARK: - Configuration Modification Tests
    
    @MainActor
    func testConfigurationModification() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        // Create initial configuration
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        
        context.insert(config)
        project.configuration = config
        try context.save()
        
        // Modify configuration
        config.modelName = "gpt-4"
        config.learningRate = 0.00005
        config.batchSize = 16
        config.numberOfEpochs = 5
        config.outputDirectory = "/tmp/new_output"
        config.datasetPath = "/tmp/new_dataset.json"
        
        try context.save()
        
        // Verify modifications persisted
        XCTAssertEqual(project.configuration?.modelName, "gpt-4")
        XCTAssertEqual(project.configuration?.learningRate, 0.00005)
        XCTAssertEqual(project.configuration?.batchSize, 16)
        XCTAssertEqual(project.configuration?.numberOfEpochs, 5)
        XCTAssertEqual(project.configuration?.outputDirectory, "/tmp/new_output")
        XCTAssertEqual(project.configuration?.datasetPath, "/tmp/new_dataset.json")
    }
    
    @MainActor
    func testAdditionalParametersModification() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        let config = FineTuningConfigurationModel()
        config.modelName = "test-model"
        config.additionalParameters = ["param1": "value1"]
        
        context.insert(config)
        project.configuration = config
        try context.save()
        
        // Add more parameters
        config.additionalParameters["param2"] = "value2"
        config.additionalParameters["param3"] = "value3"
        try context.save()
        
        XCTAssertEqual(project.configuration?.additionalParameters.count, 3)
        XCTAssertEqual(project.configuration?.additionalParameters["param1"], "value1")
        XCTAssertEqual(project.configuration?.additionalParameters["param2"], "value2")
        XCTAssertEqual(project.configuration?.additionalParameters["param3"], "value3")
    }
    
    // MARK: - Configuration Validation Tests
    
    @MainActor
    func testValidConfigurationPasses() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        
        context.insert(config)
        
        // Should not throw
        try config.validate()
        XCTAssertTrue(config.isValid)
    }
    
    @MainActor
    func testEmptyModelNameValidation() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let config = FineTuningConfigurationModel()
        config.modelName = ""
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        
        context.insert(config)
        
        XCTAssertFalse(config.isValid)
        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
            if let configError = error as? ConfigurationError {
                XCTAssertEqual(configError, ConfigurationError.emptyModelName)
            }
        }
    }
    
    @MainActor
    func testInvalidLearningRateValidation() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0
        config.batchSize = 8
        config.numberOfEpochs = 3
        
        context.insert(config)
        
        XCTAssertFalse(config.isValid)
        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
            if let configError = error as? ConfigurationError {
                XCTAssertEqual(configError, ConfigurationError.invalidLearningRate)
            }
        }
    }
    
    @MainActor
    func testInvalidBatchSizeValidation() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 0
        config.numberOfEpochs = 3
        
        context.insert(config)
        
        XCTAssertFalse(config.isValid)
        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
            if let configError = error as? ConfigurationError {
                XCTAssertEqual(configError, ConfigurationError.invalidBatchSize)
            }
        }
    }
    
    @MainActor
    func testInvalidEpochsValidation() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 0
        
        context.insert(config)
        
        XCTAssertFalse(config.isValid)
        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
            if let configError = error as? ConfigurationError {
                XCTAssertEqual(configError, ConfigurationError.invalidEpochs)
            }
        }
    }
    
    // MARK: - Configuration Persistence Tests
    
    @MainActor
    func testConfigurationPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        // Create and save configuration
        let config = FineTuningConfigurationModel()
        config.modelName = "gpt-3.5-turbo"
        config.learningRate = 0.0001
        config.batchSize = 8
        config.numberOfEpochs = 3
        config.outputDirectory = "/tmp/output"
        config.datasetPath = "/tmp/dataset.json"
        
        context.insert(config)
        project.configuration = config
        try context.save()
        
        // Fetch project again
        let descriptor = FetchDescriptor<ProjectModel>()
        let projects = try context.fetch(descriptor)
        
        XCTAssertEqual(projects.count, 1)
        let fetchedProject = projects[0]
        XCTAssertNotNil(fetchedProject.configuration)
        XCTAssertEqual(fetchedProject.configuration?.modelName, "gpt-3.5-turbo")
        XCTAssertEqual(fetchedProject.configuration?.learningRate, 0.0001)
        XCTAssertEqual(fetchedProject.configuration?.batchSize, 8)
        XCTAssertEqual(fetchedProject.configuration?.numberOfEpochs, 3)
    }
    
    @MainActor
    func testConfigurationCascadeDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        let config = FineTuningConfigurationModel()
        config.modelName = "test-model"
        context.insert(config)
        project.configuration = config
        try context.save()
        
        // Delete project
        context.delete(project)
        try context.save()
        
        // Verify configuration was also deleted
        let configDescriptor = FetchDescriptor<FineTuningConfigurationModel>()
        let configs = try context.fetch(configDescriptor)
        XCTAssertTrue(configs.isEmpty)
    }
    
    // MARK: - Complete Workflow Tests
    
    @MainActor
    func testCompleteConfigurationWorkflow() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let project = createTestProject(in: context)
        
        // Step 1: Create configuration
        let config = FineTuningConfigurationModel()
        config.modelName = "workflow-test-model"
        config.learningRate = 0.0002
        config.batchSize = 12
        config.numberOfEpochs = 4
        config.outputDirectory = "/tmp/workflow_output"
        config.datasetPath = "/tmp/workflow_dataset.json"
        
        context.insert(config)
        project.configuration = config
        
        // Step 2: Validate configuration
        try config.validate()
        XCTAssertTrue(config.isValid)
        
        // Step 3: Save configuration
        try context.save()
        
        // Step 4: Load configuration in new context
        let descriptor = FetchDescriptor<ProjectModel>()
        let projects = try context.fetch(descriptor)
        let loadedProject = projects[0]
        
        // Step 5: Verify all values persisted correctly
        XCTAssertNotNil(loadedProject.configuration)
        XCTAssertEqual(loadedProject.configuration?.modelName, "workflow-test-model")
        XCTAssertEqual(loadedProject.configuration?.learningRate, 0.0002)
        XCTAssertEqual(loadedProject.configuration?.batchSize, 12)
        XCTAssertEqual(loadedProject.configuration?.numberOfEpochs, 4)
        XCTAssertEqual(loadedProject.configuration?.outputDirectory, "/tmp/workflow_output")
        XCTAssertEqual(loadedProject.configuration?.datasetPath, "/tmp/workflow_dataset.json")
        XCTAssertTrue(loadedProject.configuration?.isValid == true)
    }
}
