//
//  KeyCommand.swift
//  ax
//

import Foundation

/// Handles the `ax key` command
struct KeyCommand {

    private struct KeyResult: Encodable {
        let keys: String
        let count: Int
    }

    static func run(args: CommandParser.KeyArgs) {
        do {
            try KeyboardEvents.pressKey(args.keys, repeatCount: args.repeatCount)
            Output.json(KeyResult(keys: args.keys, count: args.repeatCount))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(error.localizedDescription, exitCode: .actionFailed)
        }
    }
}
