//
//  CursorCommand.swift
//  ax
//

import Foundation
import AppKit

/// Handles the `ax cursor` command - returns current mouse position
struct CursorCommand {

    private struct CursorResult: Encodable {
        let x: Int
        let y: Int
    }

    static func run() {
        let location = NSEvent.mouseLocation

        // NSEvent.mouseLocation uses bottom-left origin (Cocoa coordinates)
        // Convert to top-left origin (screen coordinates used by accessibility)
        guard let screen = NSScreen.main else {
            Output.json(CursorResult(x: Int(location.x), y: Int(location.y)))
            return
        }

        let screenHeight = screen.frame.height
        let y = screenHeight - location.y

        Output.json(CursorResult(x: Int(location.x), y: Int(y)))
    }
}
