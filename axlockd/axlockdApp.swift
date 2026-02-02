//
//  axlockdApp.swift
//  axlockd
//
//  Lock daemon that suppresses human HID input while allowing ax-generated
//  events to pass through. Shows visual overlay and provides triple-Escape
//  escape hatch.
//
//  Arguments:
//    --timeout N      Timeout in seconds (default 60, max 300)
//    --ipc-file PATH  File path to write window ID to (for parent process)
//

import AppKit
import Foundation

/// Main application delegate for the lock daemon
class AppDelegate: NSObject, NSApplicationDelegate {

    private var eventTap: EventTap!
    private var overlayManager: OverlayManager!
    private var timeoutTimer: DispatchSourceTimer?
    private var ipcFile: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Parse command line arguments
        let args = CommandLine.arguments
        var timeout: Int = 60

        var i = 1
        while i < args.count {
            if args[i] == "--timeout" && i + 1 < args.count {
                timeout = Int(args[i + 1]) ?? 60
                i += 2
            } else if args[i] == "--ipc-file" && i + 1 < args.count {
                ipcFile = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        }

        // Set up the event tap
        eventTap = EventTap()
        eventTap.onTripleEscape = { [weak self] in
            self?.cleanup()
        }

        // Try to start the event tap
        guard eventTap.start() else {
            // Failed to create event tap - likely permission issue
            writeError("Failed to create event tap. Accessibility permission required.")
            NSApplication.shared.terminate(nil)
            return
        }

        // Create overlay windows
        overlayManager = OverlayManager()
        let windowIds = overlayManager.createOverlays()

        // Write the first window ID to IPC file for the parent process
        if let ipcFile = ipcFile, let firstWindowId = windowIds.first {
            try? String(firstWindowId).write(toFile: ipcFile, atomically: true, encoding: .utf8)
        }

        // Set up timeout timer
        setupTimeoutTimer(seconds: timeout)

        // Set up signal handlers
        setupSignalHandlers()
    }

    private func setupTimeoutTimer(seconds: Int) {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .seconds(seconds))
        timer.setEventHandler { [weak self] in
            self?.cleanup()
        }
        timer.resume()
        timeoutTimer = timer
    }

    private func setupSignalHandlers() {
        // Handle SIGTERM gracefully
        signal(SIGTERM) { _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }

        // Handle SIGINT (Ctrl+C) gracefully
        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }

    private func cleanup() {
        // Cancel timeout timer
        timeoutTimer?.cancel()
        timeoutTimer = nil

        // Stop the event tap
        eventTap?.stop()

        // Close overlay windows
        overlayManager?.closeOverlays()

        // Exit
        NSApplication.shared.terminate(nil)
    }

    private func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}

// MARK: - Main Entry Point

@main
struct AxLockDMain {
    static func main() {
        // Set activation policy to accessory (no dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)

        // Create and set the delegate
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate

        // Run the application
        NSApplication.shared.run()
    }
}
