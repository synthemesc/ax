//
//  ClickCommand.swift
//  ax
//

import Foundation
import CoreGraphics

/// Handles the `ax click` and `ax rightclick` commands
struct ClickCommand {

    private struct PositionResult: Encodable {
        let x: Int
        let y: Int
    }

    private struct ActionResult: Encodable {
        let action: String
        let id: String
    }

    private struct ClickResult: Encodable {
        let x: Int
        let y: Int
        let id: String
    }

    static func run(args: CommandParser.ClickArgs, rightClick: Bool = false) {
        let button: MouseEvents.Button = rightClick ? .right : .left

        if let position = args.position {
            // Click at position
            let point = CGPoint(x: position.x, y: position.y)
            MouseEvents.click(at: point, button: button)
            Output.json(PositionResult(x: position.x, y: position.y))
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
            performClick(element: element, button: button, rightClick: rightClick)
            return
        }

        // If not in registry, try to find element from apps
        // This is a limitation - element IDs are process-specific
        Output.error(.notFound("Element \(id) not found. Element IDs are only valid within the same command session."))
    }

    private static func performClick(element: Element, button: MouseEvents.Button, rightClick: Bool) {
        // Try AXPress action first (for buttons)
        if !rightClick {
            do {
                let actions = try element.actionNames()
                if actions.contains("AXPress") {
                    try element.performAction("AXPress")
                    Output.json(ActionResult(action: "AXPress", id: element.id))
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
        Output.json(ClickResult(x: Int(point.x), y: Int(point.y), id: element.id))
    }
}
