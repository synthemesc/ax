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
            runAsync { try await captureScreenshot(args: args) }
            return
        }

        guard let address = args.address else {
            // No address - list all apps
            listApps()
            return
        }

        do {
            switch address {
            case .pid(let pid):
                listWindows(pid: pid, depth: args.depth)

            case .element(let pid, let hash):
                listElement(pid: pid, hash: hash, depth: args.depth)

            case .elementRect(let pid, let hash, _, _):
                // Treat as element lookup
                listElement(pid: pid, hash: hash, depth: args.depth)

            case .elementOffset:
                // Find element at offset from given element
                let element = try AddressResolver.resolveElement(address)
                let tree = ElementTree.buildTree(from: element, maxDepth: args.depth)
                Output.json(tree)

            case .elementOffsetRect:
                // Find all elements in rect offset from element
                let rect = try AddressResolver.resolveRect(address)
                try listElementsInRect(rect, depth: args.depth)

            case .absolutePoint:
                // Find element at point
                let element = try AddressResolver.resolveElement(address)
                let tree = ElementTree.buildTree(from: element, maxDepth: args.depth)
                Output.json(tree)

            case .absoluteRect:
                // Find all elements in rect
                let rect = try AddressResolver.resolveRect(address)
                try listElementsInRect(rect, depth: args.depth)
            }
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }

    /// List elements within a rect
    private static func listElementsInRect(_ rect: ResolvedRect, depth: Int?) throws {
        let elements = try AddressResolver.elementsInRect(rect)

        if elements.isEmpty {
            Output.json([ElementInfo]())
            return
        }

        let infos = elements.map { element -> ElementInfo in
            ElementTree.buildTree(from: element, maxDepth: depth ?? 0)
        }
        Output.json(infos)
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

    /// Capture screenshot based on address
    private static func captureScreenshot(args: CommandParser.ListArgs) async throws {
        // Check screen capture permission
        if !ScreenCapture.checkPermission() {
            _ = ScreenCapture.requestPermission()
            Output.error("Screen capture permission denied. Grant access in System Settings > Privacy & Security > Screen Recording.", exitCode: .permissionDenied)
        }

        let image: CGImage

        if let address = args.address {
            switch address {
            case .pid(let pid):
                image = try await ScreenCapture.captureApp(pid: pid)
                if let path = args.screenshot {
                    try ScreenCapture.save(image, to: path)
                    listWindows(pid: pid, depth: args.depth)
                } else if args.screenshotBase64 {
                    outputBase64(image)
                }
                return

            case .element(let pid, let hash), .elementRect(let pid, let hash, _, _):
                let id = "\(pid):\(hash)"
                guard let axElement = ElementRegistry.shared.lookup(id) else {
                    Output.error(.notFound("Element \(id) not found"))
                }
                let element = Element(axElement)
                guard let frame = element.frame, let elementPid = element.pid else {
                    Output.error(.actionFailed("Element has no frame or process"))
                }
                image = try await ScreenCapture.captureElement(frame: frame, pid: elementPid)
                if let path = args.screenshot {
                    try ScreenCapture.save(image, to: path)
                    let tree = ElementTree.buildTree(from: element, maxDepth: args.depth)
                    Output.json(tree)
                } else if args.screenshotBase64 {
                    outputBase64(image)
                }
                return

            case .absoluteRect(let x, let y, let width, let height):
                let rect = CGRect(x: x, y: y, width: width, height: height)
                image = try await ScreenCapture.captureRect(rect)

            case .absolutePoint, .elementOffset, .elementOffsetRect:
                // For points/offsets, find the element and capture it
                let element = try AddressResolver.resolveElement(address)
                guard let frame = element.frame, let pid = element.pid else {
                    Output.error(.actionFailed("Element has no frame or process"))
                }
                image = try await ScreenCapture.captureElement(frame: frame, pid: pid)
                if let path = args.screenshot {
                    try ScreenCapture.save(image, to: path)
                    let tree = ElementTree.buildTree(from: element, maxDepth: args.depth)
                    Output.json(tree)
                } else if args.screenshotBase64 {
                    outputBase64(image)
                }
                return
            }
        } else {
            // Full screen capture
            image = try await ScreenCapture.captureScreen()
        }

        // Output the image
        if let path = args.screenshot {
            try ScreenCapture.save(image, to: path)
            Output.json(["path": path])
        } else if args.screenshotBase64 {
            outputBase64(image)
        }
    }

    private static func outputBase64(_ image: CGImage) {
        guard let base64 = ScreenCapture.base64PNG(image) else {
            Output.error(.actionFailed("Failed to encode screenshot"))
        }
        Output.json(["screenshot": base64])
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

    /// List element tree by PID and hash
    private static func listElement(pid: pid_t, hash: CFHashCode, depth: Int?) {
        let id = "\(pid):\(hash)"
        guard let element = ElementRegistry.shared.lookup(id) else {
            Output.error(.notFound("Element \(id) not found"))
        }

        let tree = ElementTree.buildTree(from: Element(element), maxDepth: depth)
        Output.json(tree)
    }
}
