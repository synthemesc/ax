//
//  SetCommand.swift
//  ax
//

import Foundation
import ApplicationServices

/// Handles the `ax set` command - sets an element's value
struct SetCommand {

    private struct SetResult: Encodable {
        let id: String
        let value: String
    }

    static func run(args: CommandParser.SetArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)
            let id = element.id

            // Set the value attribute
            try element.setAttribute(kAXValueAttribute, value: args.value as CFTypeRef)

            Output.json(SetResult(id: id, value: args.value))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
