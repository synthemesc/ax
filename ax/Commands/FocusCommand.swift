//
//  FocusCommand.swift
//  ax
//

import Foundation
import AppKit
import ApplicationServices

/// Handles the `ax focus` command
struct FocusCommand {

    private struct FocusResult: Encodable {
        let focused: String
    }

    static func run(args: CommandParser.FocusArgs) {
        // Check if target is a PID (numeric) or element ID (hex)
        if let pid = Int32(args.target) {
            focusApp(pid: pid)
        } else {
            focusElement(id: args.target)
        }
    }

    /// Focus an application by PID
    private static func focusApp(pid: pid_t) {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            Output.error(.notFound("No application with pid \(pid)"))
        }

        let success = app.activate(options: [.activateIgnoringOtherApps])
        if !success {
            Output.error(.actionFailed("Failed to activate application"))
        }

        Output.json(FocusResult(focused: "pid:\(pid)"))
    }

    /// Focus an element by ID
    private static func focusElement(id: String) {
        guard let axElement = ElementRegistry.shared.lookup(id) else {
            Output.error(.notFound("Element \(id) not found"))
        }

        let element = Element(axElement)

        // Try to set focus attribute
        do {
            try element.setAttribute(kAXFocusedAttribute, value: true as CFBoolean)
            Output.json(FocusResult(focused: id))
        } catch {
            // If setting focus fails, try to bring the window to front
            if let window = findContainingWindow(element) {
                do {
                    try window.performAction("AXRaise")
                    try element.setAttribute(kAXFocusedAttribute, value: true as CFBoolean)
                    Output.json(FocusResult(focused: id))
                } catch {
                    Output.error(.actionFailed("Failed to focus element"))
                }
            } else {
                Output.error(.actionFailed("Failed to focus element"))
            }
        }
    }

    /// Find the window containing an element
    private static func findContainingWindow(_ element: Element) -> Element? {
        var current: Element? = element
        while let el = current {
            if el.role == "AXWindow" {
                return el
            }
            current = el.parent
        }
        return nil
    }
}
