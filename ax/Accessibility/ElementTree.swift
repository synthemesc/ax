//
//  ElementTree.swift
//  ax
//

import Foundation
import CoreGraphics

/// Handles recursive traversal of the accessibility element tree
struct ElementTree {

    /// Traverse the element tree up to a maximum depth
    /// - Parameters:
    ///   - element: The root element to start from
    ///   - maxDepth: Maximum depth to traverse (nil for unlimited)
    ///   - currentDepth: Current depth in the tree (used internally)
    ///   - parentOrigin: The absolute position of the parent element (for calculating relative frame)
    /// - Returns: ElementInfo tree structure
    static func buildTree(from element: Element, maxDepth: Int?, currentDepth: Int = 0, parentOrigin: CGPoint? = nil) -> ElementInfo {
        // Register element to keep it alive
        let id = ElementRegistry.shared.register(element.axElement)

        // Get actions (convert to snake_case display format)
        let actions = (try? element.actionNames())?.map { actionName in
            AXNameFormatter.formatForDisplay(actionName)
        } ?? []

        // Get absolute position and size
        let absoluteFrame = element.frame
        let absoluteOrigin = element.position

        // Calculate relative frame (position relative to parent)
        let relativeFrame: FrameInfo?
        if let frame = absoluteFrame {
            if let parent = parentOrigin {
                // Relative to parent
                relativeFrame = FrameInfo(
                    x: Int(frame.origin.x - parent.x),
                    y: Int(frame.origin.y - parent.y),
                    width: Int(frame.size.width),
                    height: Int(frame.size.height)
                )
            } else {
                // No parent, use absolute (for root elements)
                relativeFrame = FrameInfo(rect: frame)
            }
        } else {
            relativeFrame = nil
        }

        // Origin is always absolute screen position
        let origin = absoluteOrigin.map { PointInfo(x: Int($0.x), y: Int($0.y)) }

        // Get children if we haven't hit max depth
        var children: [ElementInfo]? = nil
        if maxDepth == nil || currentDepth < maxDepth! {
            let childElements = element.children
            if !childElements.isEmpty {
                children = childElements.map { child in
                    buildTree(from: child, maxDepth: maxDepth, currentDepth: currentDepth + 1, parentOrigin: absoluteOrigin)
                }
            }
        }

        // Build the ElementInfo
        // Format role and subrole to snake_case display format
        return ElementInfo(
            id: id,
            role: element.role.map { AXNameFormatter.formatForDisplay($0) },
            subrole: element.subrole.map { AXNameFormatter.formatForDisplay($0) },
            title: element.title,
            description: element.description,
            value: formatValue(element.value),
            label: element.roleDescription,
            help: element.help,
            identifier: element.identifier,
            frame: relativeFrame,
            origin: origin,
            enabled: element.isEnabled ? nil : false,  // Only include if false
            focused: element.isFocused ? true : nil,   // Only include if true
            actions: actions.isEmpty ? nil : actions,
            children: children
        )
    }

    /// Format a value for JSON output
    private static func formatValue(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        switch value {
        case let string as String:
            // Truncate very long strings
            if string.count > 500 {
                return String(string.prefix(500)) + "..."
            }
            return string
        case let number as NSNumber:
            return number.stringValue
        case let bool as Bool:
            return bool ? "true" : "false"
        default:
            return String(describing: value)
        }
    }
}
