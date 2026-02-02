//
//  LockState.swift
//  ax
//
//  Manages the lock state using a PID file (~/.ax-lock.pid).
//  Handles stale PID detection when process no longer exists.
//

import Foundation

/// Manages the ax lock state via a PID file
struct LockState {

    /// Path to the PID file
    private static let pidFilePath = NSHomeDirectory() + "/.ax-lock.pid"

    /// Check if ax is currently locked and return the daemon PID
    /// Returns nil if not locked or if the PID file points to a dead process
    static func isLocked() -> pid_t? {
        let path = pidFilePath

        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        guard let contents = try? String(contentsOfFile: path, encoding: .utf8),
              let pid = pid_t(contents.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            // Invalid PID file, clean it up
            try? FileManager.default.removeItem(atPath: path)
            return nil
        }

        // Check if process is still running
        if kill(pid, 0) == 0 {
            return pid
        } else {
            // Process doesn't exist, clean up stale PID file
            try? FileManager.default.removeItem(atPath: path)
            return nil
        }
    }

    /// Write the daemon PID to the lock file
    static func writePID(_ pid: pid_t) throws {
        let path = pidFilePath
        try String(pid).write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Remove the PID file
    static func removePIDFile() {
        let path = pidFilePath
        try? FileManager.default.removeItem(atPath: path)
    }
}
