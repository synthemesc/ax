//
//  ElementTree.swift
//  ax
//

import Foundation

/// Handles recursive traversal of the accessibility element tree
struct ElementTree {

    /// Traverse the element tree up to a maximum depth
    /// - Parameters:
    ///   - element: The root element to start from
    ///   - maxDepth: Maximum depth to traverse (nil for unlimited)
    ///   - currentDepth: Current depth in the tree (used internally)
    /// - Returns: ElementInfo tree structure
    static func buildTree(from element: Element, maxDepth: Int?, currentDepth: Int = 0) -> ElementInfo {
        // Register element to keep it alive
        let id = ElementRegistry.shared.register(element.axElement)

        // Get actions (strip AX prefix and lowercase)
        let actions = (try? element.actionNames())?.map { actionName in
            formatActionName(actionName)
        } ?? []

        // Get children if we haven't hit max depth
        var children: [ElementInfo]? = nil
        if maxDepth == nil || currentDepth < maxDepth! {
            let childElements = element.children
            if !childElements.isEmpty {
                children = childElements.map { child in
                    buildTree(from: child, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                }
            }
        }

        // Build the ElementInfo
        return ElementInfo(
            id: id,
            role: element.role,
            subrole: element.subrole,
            title: element.title,
            description: element.description,
            value: formatValue(element.value),
            label: element.roleDescription,
            help: element.help,
            identifier: element.identifier,
            frame: element.frame.map(FrameInfo.init),
            enabled: element.isEnabled ? nil : false,  // Only include if false
            focused: element.isFocused ? true : nil,   // Only include if true
            actions: actions.isEmpty ? nil : actions,
            children: children
        )
    }

    /// Format action name: strip "AX" prefix and lowercase first letter
    private static func formatActionName(_ name: String) -> String {
        var result = name
        if result.hasPrefix("AX") {
            result = String(result.dropFirst(2))
        }
        // Lowercase first character
        if let first = result.first {
            result = first.lowercased() + result.dropFirst()
        }
        return result
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
