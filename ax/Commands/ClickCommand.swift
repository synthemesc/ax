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

        if let position = args.position {
            // Click at position
            let point = CGPoint(x: position.x, y: position.y)
            MouseEvents.click(at: point, button: button)
            Output.json(ClickResult(id: nil, method: "mouse", x: position.x, y: position.y))
        } else if let target = args.target {
            // Click on element
            clickElement(id: target, button: button, rightClick: rightClick)
        } else {
            Output.error(.invalidArguments("click requires either an element id or --pos x,y"))
        }
    }

    private static func clickElement(id: String, button: MouseEvents.Button, rightClick: Bool) {
        // First, try to look up from registry
        if let axElement = ElementRegistry.shared.lookup(id) {
            let element = Element(axElement)
            performClick(element: element, id: id, button: button, rightClick: rightClick)
            return
        }

        // If not in registry, try to find element from apps
        // This is a limitation - element IDs are process-specific
        Output.error(.notFound("Element \(id) not found. Element IDs are only valid within the same command session."))
    }

    private static func performClick(element: Element, id: String, button: MouseEvents.Button, rightClick: Bool) {
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
