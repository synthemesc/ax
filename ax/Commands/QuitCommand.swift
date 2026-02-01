//
//  QuitCommand.swift
//  ax
//

import Foundation
import AppKit

/// Handles the `ax quit` command
struct QuitCommand {

    private struct QuitResult: Encodable {
        let quit: Int32
    }

    static func run(args: CommandParser.QuitArgs) {
        let pid = args.pid

        guard let app = NSRunningApplication(processIdentifier: pid) else {
            Output.error(.notFound("No application with pid \(pid)"))
        }

        // Try graceful termination first
        let success = app.terminate()

        if !success {
            // If graceful termination fails, try force termination
            let forceSuccess = app.forceTerminate()
            if !forceSuccess {
                Output.error(.actionFailed("Failed to quit application"))
            }
        }

        Output.json(QuitResult(quit: pid))
    }
}
