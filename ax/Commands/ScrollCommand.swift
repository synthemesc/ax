//
//  ScrollCommand.swift
//  ax
//

import Foundation
import CoreGraphics

/// Handles the `ax scroll` command
struct ScrollCommand {

    private struct ScrollResult: Encodable {
        let direction: String
        let amount: Int
        let x: Int
        let y: Int
    }

    static func run(args: CommandParser.ScrollArgs) {
        // Determine scroll position
        let point: CGPoint

        if let position = args.position {
            point = CGPoint(x: position.x, y: position.y)
        } else if let target = args.target {
            // Get element center
            guard let axElement = ElementRegistry.shared.lookup(target) else {
                Output.error(.notFound("Element \(target) not found"))
            }
            let element = Element(axElement)
            guard let frame = element.frame else {
                Output.error(.actionFailed("Element has no position"))
            }
            point = CGPoint(x: frame.midX, y: frame.midY)
        } else {
            // Use current mouse position
            point = MouseEvents.currentPosition
        }

        // Calculate scroll deltas
        let (deltaX, deltaY) = scrollDeltas(direction: args.direction, amount: args.amount)

        // Create and post scroll event
        scroll(at: point, deltaX: deltaX, deltaY: deltaY)

        Output.json(ScrollResult(
            direction: args.direction,
            amount: args.amount,
            x: Int(point.x),
            y: Int(point.y)
        ))
    }

    private static func scrollDeltas(direction: String, amount: Int) -> (Int32, Int32) {
        switch direction {
        case "up":
            return (0, Int32(amount))
        case "down":
            return (0, Int32(-amount))
        case "left":
            return (Int32(amount), 0)
        case "right":
            return (Int32(-amount), 0)
        default:
            return (0, 0)
        }
    }

    private static func scroll(at point: CGPoint, deltaX: Int32, deltaY: Int32) {
        // Move mouse to position first
        MouseEvents.move(to: point)

        // Create scroll event
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) else {
            return
        }

        event.post(tap: .cghidEventTap)
    }
}
