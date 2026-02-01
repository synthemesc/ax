//
//  LaunchCommand.swift
//  ax
//

import Foundation
import AppKit

/// Handles the `ax launch` command
struct LaunchCommand {

    private struct LaunchResult: Encodable {
        let pid: Int32
        let bundleId: String

        enum CodingKeys: String, CodingKey {
            case pid
            case bundleId = "bundle_id"
        }
    }

    static func run(args: CommandParser.LaunchArgs) {
        let bundleId = args.bundleId

        // Check if app is already running
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleId
        }

        if let runningApp = runningApps.first {
            // App is already running, just activate it
            runningApp.activate(options: [.activateIgnoringOtherApps])
            Output.json(LaunchResult(pid: runningApp.processIdentifier, bundleId: bundleId))
            return
        }

        // Launch the app
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            Output.error(.notFound("No application with bundle id '\(bundleId)'"))
        }

        // Use synchronous approach with semaphore
        let semaphore = DispatchSemaphore(value: 0)
        var launchedApp: NSRunningApplication?
        var launchError: Error?

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            launchedApp = app
            launchError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let error = launchError {
            Output.error(.actionFailed("Failed to launch: \(error.localizedDescription)"))
        }

        guard let app = launchedApp else {
            Output.error(.actionFailed("Failed to launch application"))
        }

        Output.json(LaunchResult(pid: app.processIdentifier, bundleId: bundleId))
    }
}
