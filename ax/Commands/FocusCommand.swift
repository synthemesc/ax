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
        do {
            switch args.address {
            case .pid(let pid):
                focusApp(pid: pid)

            case .element, .elementRect, .elementOffset, .elementOffsetRect:
                let element = try AddressResolver.resolveElement(args.address)
                focusElement(element: element)

            case .absolutePoint, .absoluteRect:
                // Focus element at coordinates
                let element = try AddressResolver.resolveElement(args.address)
                focusElement(element: element)
            }
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
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

    /// Focus an element
    private static func focusElement(element: Element) {
        let id = element.id

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
