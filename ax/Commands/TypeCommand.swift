//
//  TypeCommand.swift
//  ax
//

import Foundation
import ApplicationServices
import CoreGraphics

/// Handles the `ax type` command
struct TypeCommand {

    static func run(args: CommandParser.TypeArgs) {
        // If address is specified, focus it first
        if let address = args.address {
            do {
                let element = try AddressResolver.resolveElement(address)
                focusElement(element: element)
            } catch let error as AXError {
                Output.error(error)
            } catch {
                Output.error(.actionFailed(error.localizedDescription))
            }
        }

        // Type the text
        KeyboardEvents.type(args.text)

        Output.json(["typed": args.text.count])
    }

    private static func focusElement(element: Element) {
        // Try to set focus
        do {
            try element.setAttribute(kAXFocusedAttribute, value: true as CFBoolean)
        } catch {
            // Element might not support focus, try clicking instead
            if let frame = element.frame {
                MouseEvents.click(at: CGPoint(x: frame.midX, y: frame.midY))
                usleep(100000)  // 100ms delay for focus to settle
            } else {
                Output.error(.actionFailed("Cannot focus element \(element.id)"))
            }
        }
    }
}
