//
//  ClickCommand.swift
//  ax
//

import Foundation
import CoreGraphics

/// Handles the `ax click` and `ax rightclick` commands
struct ClickCommand {

    /// Unified click result with method field for AI agents
    private struct ClickResult: Encodable {
        let id: String?
        let method: String  // "press" or "mouse"
        let x: Int?
        let y: Int?
    }

    static func run(args: CommandParser.ClickArgs, rightClick: Bool = false) {
        let button: MouseEvents.Button = rightClick ? .right : .left

        guard let address = args.address else {
            Output.error(.invalidArguments("click requires an address (element ID or @x,y)"))
        }

        do {
            // Try to get an element from the address
            if address.isElement || address.isRect {
                // For element-based addresses, try to click the element
                let element = try AddressResolver.resolveElement(address)
                performClick(element: element, address: address, button: button, rightClick: rightClick)
            } else {
                // For point addresses, click at coordinates
                let point = try AddressResolver.resolvePoint(address)
                MouseEvents.click(at: point.cgPoint, button: button)
                Output.json(ClickResult(id: nil, method: "mouse", x: point.x, y: point.y))
            }
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }

    private static func performClick(element: Element, address: Address, button: MouseEvents.Button, rightClick: Bool) {
        let id = element.id

        // For element offset addresses, click at the offset point, not the element
        switch address {
        case .elementOffset, .elementOffsetRect:
            do {
                let point = try AddressResolver.resolvePoint(address)
                MouseEvents.click(at: point.cgPoint, button: button)
                Output.json(ClickResult(id: id, method: "mouse", x: point.x, y: point.y))
            } catch {
                Output.error(.actionFailed(error.localizedDescription))
            }
            return
        default:
            break
        }

        // Try AXPress action first (for buttons), unless right-clicking
        if !rightClick {
            do {
                let actions = try element.actionNames()
                if actions.contains("AXPress") {
                    try element.performAction("AXPress")
                    // Get position for context even when using press
                    let (x, y) = elementCenter(element)
                    Output.json(ClickResult(id: id, method: "press", x: x, y: y))
                    return
                }
            } catch {
                // Fall through to coordinate click
            }
        }

        // Fall back to coordinate click
        guard let frame = element.frame else {
            Output.error(.actionFailed("Element has no position"))
        }

        // Click at center of element
        let point = CGPoint(
            x: frame.midX,
            y: frame.midY
        )

        MouseEvents.click(at: point, button: button)
        Output.json(ClickResult(id: id, method: "mouse", x: Int(point.x), y: Int(point.y)))
    }

    /// Get the center coordinates of an element
    private static func elementCenter(_ element: Element) -> (Int?, Int?) {
        guard let frame = element.frame else { return (nil, nil) }
        return (Int(frame.midX), Int(frame.midY))
    }
}
