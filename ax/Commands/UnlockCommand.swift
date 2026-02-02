//
//  UnlockCommand.swift
//  ax
//
//  Handles the `ax unlock` command - unlocks human HID input by
//  terminating the axlockd daemon.
//

import Foundation

/// Result structure for unlock command
struct UnlockResult: Codable {
    let status: String
}

/// Handles the `ax unlock` command
struct UnlockCommand {

    static func run() {
        // Check if locked
        guard let pid = LockState.isLocked() else {
            Output.json(UnlockResult(status: "not_locked"))
            return
        }

        // Send SIGTERM to the daemon
        kill(pid, SIGTERM)

        // Wait up to 1 second for it to terminate
        var terminated = false
        for _ in 0..<10 {
            usleep(100_000)  // 100ms
            if kill(pid, 0) != 0 {
                terminated = true
                break
            }
        }

        // If still running, force kill
        if !terminated {
            kill(pid, SIGKILL)
            usleep(100_000)  // Give it a moment
        }

        // Remove PID file
        LockState.removePIDFile()

        Output.json(UnlockResult(status: "unlocked"))
    }
}
