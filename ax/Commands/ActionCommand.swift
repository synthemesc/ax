//
//  ActionCommand.swift
//  ax
//

import Foundation

/// Handles the `ax action` command
struct ActionCommand {

    private struct ActionResult: Encodable {
        let action: String
        let id: String
    }

    static func run(args: CommandParser.ActionArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)
            let id = element.id

            // Convert user-friendly action name to AX action name
            let axAction = AXNameFormatter.formatForAPI(args.action)

            // Verify action is available
            let actions = try element.actionNames()
            guard actions.contains(axAction) else {
                let available = actions.map { AXNameFormatter.formatForDisplay($0) }.joined(separator: ", ")
                Output.error(.invalidArguments("Action '\(args.action)' not available. Available actions: \(available)"))
            }

            try element.performAction(axAction)
            // Output in display format (snake_case)
            Output.json(ActionResult(action: AXNameFormatter.formatForDisplay(axAction), id: id))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(error.localizedDescription, exitCode: .actionFailed)
        }
    }
}
