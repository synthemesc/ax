//
//  ResizeCommand.swift
//  ax
//

import Foundation
import ApplicationServices

/// Handles the `ax resize` command - resizes a window/element
struct ResizeCommand {

    private struct ResizeResult: Encodable {
        let id: String
        let width: Int
        let height: Int
    }

    static func run(args: CommandParser.ResizeArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)
            let id = element.id

            // Create size value
            let size = CGSize(width: CGFloat(args.width), height: CGFloat(args.height))

            // Set the size attribute
            try element.setAttribute(kAXSizeAttribute, value: size)

            Output.json(ResizeResult(id: id, width: args.width, height: args.height))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
