//
//  MoveCommand.swift
//  ax
//

import Foundation
import ApplicationServices

/// Handles the `ax move` command - moves a window/element to a new position
struct MoveCommand {

    private struct MoveResult: Encodable {
        let id: String
        let x: Int
        let y: Int
    }

    static func run(args: CommandParser.MoveArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)
            let destination = try AddressResolver.resolvePoint(args.destination)
            let id = element.id

            // Create position value
            let position = CGPoint(x: CGFloat(destination.x), y: CGFloat(destination.y))

            // Set the position attribute
            try element.setAttribute(kAXPositionAttribute, value: position)

            Output.json(MoveResult(id: id, x: destination.x, y: destination.y))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
