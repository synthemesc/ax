//
//  ListCommand.swift
//  ax
//

import Foundation
import AppKit

/// Handles the `ax ls` command
struct ListCommand {

    static func run(args: CommandParser.ListArgs) {
        // Handle screenshot mode
        if args.screenshot != nil || args.screenshotBase64 {
            if let target = args.target {
                if ElementID.isElementID(target) {
                    // Element screenshot
                    runAsync { try await captureElementAndOutput(id: target, args: args) }
                } else if let pid = Int32(target) {
                    // App screenshot
                    runAsync { try await captureAndOutput(pid: pid, args: args) }
                } else {
                    Output.error(.invalidArguments("Invalid target: \(target). Use a PID or element ID."))
                }
            } else {
                // Full screen screenshot
                runAsync { try await captureAndOutput(pid: nil, args: args) }
            }
            return
        }

        if let target = args.target {
            // Check if it's a PID (numeric) or element ID (pid-hash format)
            if ElementID.isElementID(target) {
                listElement(id: target, depth: args.depth)
            } else if let pid = Int32(target) {
                listWindows(pid: pid, depth: args.depth)
            } else {
                Output.error(.invalidArguments("Invalid target: \(target). Use a PID or element ID."))
            }
        } else {
            listApps()
        }
    }

    /// Run an async block synchronously
    private static func runAsync(_ block: @escaping () async throws -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                try await block()
            } catch let error as AXError {
                Output.error(error)
            } catch {
                Output.error(error.localizedDescription, exitCode: .actionFailed)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    /// Capture screenshot and output
    private static func captureAndOutput(pid: pid_t?, args: CommandParser.ListArgs) async throws {
        // Check screen capture permission
        if !ScreenCapture.checkPermission() {
            _ = ScreenCapture.requestPermission()
            Output.error("Screen capture permission denied. Grant access in System Settings > Privacy & Security > Screen Recording.", exitCode: .permissionDenied)
        }

        // Capture the image
        let image: CGImage
        if let pid = pid {
            image = try await ScreenCapture.captureApp(pid: pid)
        } else {
            image = try await ScreenCapture.captureScreen()
        }

        // Output as file or base64
        if let path = args.screenshot {
            try ScreenCapture.save(image, to: path)
            // If also listing, continue to list after saving
            if let pid = pid {
                listWindows(pid: pid, depth: args.depth)
            } else {
                Output.json(["path": path])
            }
        } else if args.screenshotBase64 {
            guard let base64 = ScreenCapture.base64PNG(image) else {
                Output.error(.actionFailed("Failed to encode screenshot"))
            }
            Output.json(["screenshot": base64])
        }
    }

    /// Capture element screenshot and output
    private static func captureElementAndOutput(id: String, args: CommandParser.ListArgs) async throws {
        // Check screen capture permission
        if !ScreenCapture.checkPermission() {
            _ = ScreenCapture.requestPermission()
            Output.error("Screen capture permission denied. Grant access in System Settings > Privacy & Security > Screen Recording.", exitCode: .permissionDenied)
        }

        // Look up the element
        guard let axElement = ElementRegistry.shared.lookup(id) else {
            Output.error(.notFound("Element \(id) not found"))
        }

        let element = Element(axElement)

        // Get element's frame and PID
        guard let frame = element.frame else {
            Output.error(.actionFailed("Element has no frame"))
        }

        guard let pid = element.pid else {
            Output.error(.actionFailed("Could not determine element's process"))
        }

        // Capture the element
        let image = try await ScreenCapture.captureElement(frame: frame, pid: pid)

        // Output as file or base64
        if let path = args.screenshot {
            try ScreenCapture.save(image, to: path)
            // Also output the element info
            listElement(id: id, depth: args.depth)
        } else if args.screenshotBase64 {
            guard let base64 = ScreenCapture.base64PNG(image) else {
                Output.error(.actionFailed("Failed to encode screenshot"))
            }
            Output.json(["screenshot": base64])
        }
    }

    /// List all running applications with display info
    private static func listApps() {
        let displays = DisplayInfo.all()

        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }  // Only GUI apps
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
            .map { app in
                AppInfo(
                    pid: app.processIdentifier,
                    name: app.localizedName,
                    bundleId: app.bundleIdentifier
                )
            }

        Output.json(AppListResult(displays: displays, apps: apps))
    }

    /// List windows for an application by PID
    private static func listWindows(pid: pid_t, depth: Int?) {
        let app = Element.application(pid: pid)

        // Check if app exists
        guard app.role != nil else {
            Output.error(.notFound("No application with pid \(pid)"))
        }

        let windows = app.windows

        if windows.isEmpty {
            // No windows, but app exists - return empty array
            Output.json([WindowInfo]())
            return
        }

        let mainWindow = app.mainWindow
        let focusedWindow = app.focusedWindow

        // If depth is specified, include element tree for each window
        if let depth = depth, depth > 0 {
            let windowInfos = windows.map { window -> ElementInfo in
                ElementTree.buildTree(from: window, maxDepth: depth)
            }
            Output.json(windowInfos)
        } else {
            let windowInfos = windows.map { window -> WindowInfo in
                let id = ElementRegistry.shared.register(window.axElement)
                return WindowInfo(
                    id: id,
                    title: window.title,
                    frame: window.frame,
                    main: window == mainWindow,
                    focused: window == focusedWindow
                )
            }
            Output.json(windowInfos)
        }
    }

    /// List element tree starting from an element ID
    private static func listElement(id: String, depth: Int?) {
        guard let element = ElementRegistry.shared.lookup(id) else {
            Output.error(.notFound("Element \(id) not found"))
        }

        let tree = ElementTree.buildTree(from: Element(element), maxDepth: depth)
        Output.json(tree)
    }
}
