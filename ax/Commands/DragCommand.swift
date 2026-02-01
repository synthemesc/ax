//
//  DragCommand.swift
//  ax
//

import Foundation
import CoreGraphics

/// Handles the `ax drag` command - drags from one position to another
struct DragCommand {

    private struct DragResult: Encodable {
        let from: PointResult
        let to: PointResult
    }

    private struct PointResult: Encodable {
        let x: Int
        let y: Int
    }

    static func run(args: CommandParser.DragArgs) {
        do {
            let startPoint = try AddressResolver.resolvePoint(args.from)
            let endPoint = try AddressResolver.resolvePoint(args.to)

            // Perform the drag
            MouseEvents.drag(from: startPoint.cgPoint, to: endPoint.cgPoint)

            Output.json(DragResult(
                from: PointResult(x: startPoint.x, y: startPoint.y),
                to: PointResult(x: endPoint.x, y: endPoint.y)
            ))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
