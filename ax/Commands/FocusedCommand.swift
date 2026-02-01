//
//  FocusedCommand.swift
//  ax
//

import Foundation
import ApplicationServices

/// Handles the `ax focused` command - returns the currently focused element
struct FocusedCommand {

    static func run() {
        // Get system-wide element for querying focused element
        let systemWide = AXUIElementCreateSystemWide()

        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard result == .success, let axElement = focusedValue else {
            Output.error(.notFound("No focused element"))
        }

        // Cast to AXUIElement
        let element = Element(axElement as! AXUIElement)

        // Register and build tree
        _ = ElementRegistry.shared.register(element.axElement)
        let tree = ElementTree.buildTree(from: element, maxDepth: 0)
        Output.json(tree)
    }
}
