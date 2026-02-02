//
//  LockCommand.swift
//  ax
//
//  Handles the `ax lock` command - locks human HID input while allowing
//  programmatic ax commands to pass through.
//

import Foundation

/// Result structure for lock command
struct LockResult: Codable {
    let status: String
    let pid: Int32
    let window_id: UInt32
    let timeout: Int
}

/// Error result when already locked
struct LockErrorResult: Codable {
    let error: String
    let pid: Int32
}

/// Handles the `ax lock` command
struct LockCommand {

    static func run(args: CommandParser.LockArgs) {
        // Check if already locked
        if let existingPid = LockState.isLocked() {
            Output.json(LockErrorResult(error: "already locked", pid: existingPid))
            exit(ExitCode.actionFailed.rawValue)
        }

        // Find the axlockd binary
        // It should be in the same DerivedData products directory as ax,
        // inside axlockd.app/Contents/MacOS/axlockd
        guard let axlockdPath = findAxlockdPath() else {
            Output.error(.actionFailed("Could not find axlockd daemon"))
        }

        // Create a temporary file for IPC (to receive window ID from daemon)
        let ipcFile = NSTemporaryDirectory() + "ax-lock-\(ProcessInfo.processInfo.processIdentifier).ipc"

        // Spawn axlockd subprocess
        let process = Process()
        process.executableURL = URL(fileURLWithPath: axlockdPath)
        process.arguments = [
            "--timeout", String(args.timeout),
            "--ipc-file", ipcFile
        ]

        do {
            try process.run()
        } catch {
            Output.error(.actionFailed("Failed to launch axlockd: \(error.localizedDescription)"))
        }

        // Wait a moment for the daemon to start and write the IPC file
        usleep(500_000)  // 500ms

        // Read window ID from IPC file
        var windowId: UInt32 = 0
        if let str = try? String(contentsOfFile: ipcFile, encoding: .utf8) {
            windowId = UInt32(str.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        }
        // Clean up IPC file
        try? FileManager.default.removeItem(atPath: ipcFile)

        // Write PID file
        let pid = process.processIdentifier
        do {
            try LockState.writePID(pid)
        } catch {
            // Kill the daemon if we can't write the PID file
            process.terminate()
            Output.error(.actionFailed("Failed to write lock file: \(error.localizedDescription)"))
        }

        // Output result
        Output.json(LockResult(
            status: "locked",
            pid: pid,
            window_id: windowId,
            timeout: args.timeout
        ))
    }

    /// Find the path to axlockd binary
    private static func findAxlockdPath() -> String? {
        // Get the path to the current executable
        let executablePath = CommandLine.arguments[0]
        let executableURL = URL(fileURLWithPath: executablePath).standardized

        // axlockd should be in the same Products directory
        // ax is at: .../Products/Debug/ax
        // axlockd is at: .../Products/Debug/axlockd.app/Contents/MacOS/axlockd
        let productsDir = executableURL.deletingLastPathComponent()
        let axlockdPath = productsDir
            .appendingPathComponent("axlockd.app")
            .appendingPathComponent("Contents")
            .appendingPathComponent("MacOS")
            .appendingPathComponent("axlockd")
            .path

        if FileManager.default.fileExists(atPath: axlockdPath) {
            return axlockdPath
        }

        // Also check in the same directory (for when installed)
        let sameDirPath = productsDir.appendingPathComponent("axlockd").path
        if FileManager.default.fileExists(atPath: sameDirPath) {
            return sameDirPath
        }

        return nil
    }
}
