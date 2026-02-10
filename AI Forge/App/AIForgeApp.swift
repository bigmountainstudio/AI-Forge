// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio

import SwiftUI
import SwiftData
import AppKit

@main
struct AIForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appDelegate, appDelegate)
        }
        .modelContainer(for: [ProjectModel.self, WorkflowStepModel.self, FineTuningConfigurationModel.self])
    }
}

// MARK: - App Delegate for Shutdown Handling

class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContext: ModelContext?
    
    func applicationWillTerminate(_ notification: Notification) {
        // Ensure all pending saves complete before exit
        guard let context = modelContext else { return }
        
        do {
            // Check if there are unsaved changes
            if context.hasChanges {
                try context.save()
                ErrorLogger.log("Successfully saved all pending changes before application termination", severity: .info, category: .database)
            }
        } catch {
            ErrorLogger.logCritical(error, message: "Failed to save pending changes during application shutdown", category: .database)
            
            // Show alert to user about unsaved changes
            let alert = NSAlert()
            alert.messageText = "Failed to Save Changes"
            alert.informativeText = "Some changes could not be saved before closing. Your recent work may be lost."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - Environment Key for AppDelegate

private struct AppDelegateKey: EnvironmentKey {
    static let defaultValue: AppDelegate? = nil
}

extension EnvironmentValues {
    var appDelegate: AppDelegate? {
        get { self[AppDelegateKey.self] }
        set { self[AppDelegateKey.self] = newValue }
    }
}
