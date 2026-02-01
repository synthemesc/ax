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
        guard let axElement = ElementRegistry.shared.lookup(args.target) else {
            Output.error(.notFound("Element \(args.target) not found"))
        }

        let element = Element(axElement)

        // Convert user-friendly action name to AX action name
        let axAction = formatActionName(args.action)

        do {
            // Verify action is available
            let actions = try element.actionNames()
            guard actions.contains(axAction) else {
                let available = actions.map { formatActionNameForDisplay($0) }.joined(separator: ", ")
                Output.error(.invalidArguments("Action '\(args.action)' not available. Available actions: \(available)"))
            }

            try element.performAction(axAction)
            Output.json(ActionResult(action: axAction, id: args.target))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(error.localizedDescription, exitCode: .actionFailed)
        }
    }

    /// Convert user-friendly action name to AX action name
    /// e.g., "press" -> "AXPress", "showMenu" -> "AXShowMenu"
    private static func formatActionName(_ name: String) -> String {
        // If already has AX prefix, use as-is
        if name.hasPrefix("AX") {
            return name
        }

        // Capitalize first letter and add AX prefix
        let capitalized = name.prefix(1).uppercased() + name.dropFirst()
        return "AX" + capitalized
    }

    /// Convert AX action name to user-friendly name for display
    /// e.g., "AXPress" -> "press", "AXShowMenu" -> "showMenu"
    private static func formatActionNameForDisplay(_ name: String) -> String {
        var result = name
        if result.hasPrefix("AX") {
            result = String(result.dropFirst(2))
        }
        // Lowercase first character
        if let first = result.first {
            result = first.lowercased() + result.dropFirst()
        }
        return result
    }
}
