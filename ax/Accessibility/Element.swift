//
//  Element.swift
//  ax
//
//  Wrapper around AXUIElement providing safe, Swift-friendly attribute access.
//
//  Design Pattern (from AXSwift):
//  - attribute<T>() returns nil for .noValue/.attributeUnsupported (not errors)
//  - attributes() batch-fetches multiple attrs in one IPC call for performance
//  - AXValue types (CGPoint, CGSize, CGRect, CFRange) auto-unpack to Swift types
//  - No manual memory management - CF types bridged at API boundaries
//
//  Usage:
//    let element = Element.application(pid: 1234)
//    let title: String? = try element.attribute(kAXTitleAttribute)
//    let children = element.children  // [Element]
//

import Foundation
import ApplicationServices
import CoreGraphics

/// Wrapper around AXUIElement with safe attribute access.
/// Pattern inspired by AXSwift - returns nil for missing/unsupported attributes.
final class Element {
    let axElement: AXUIElement

    /// The element's stable ID (pid-hash format)
    var id: String {
        ElementID.makeID(for: axElement) ?? "unknown"
    }

    init(_ element: AXUIElement) {
        self.axElement = element
    }

    /// Create an Element for an application by PID
    static func application(pid: pid_t) -> Element {
        return Element(AXUIElementCreateApplication(pid))
    }

    /// Create an Element for the system-wide element
    static func systemWide() -> Element {
        return Element(AXUIElementCreateSystemWide())
    }

    // MARK: - Attribute Access

    /// Get an attribute value. Returns nil for .noValue or .attributeUnsupported.
    /// Throws for other errors.
    func attribute<T>(_ name: String) throws -> T? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axElement, name as CFString, &value)

        switch result {
        case .success:
            guard let value = value else { return nil }
            return unpackValue(value) as? T
        case .noValue, .attributeUnsupported:
            return nil
        default:
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            return nil
        }
    }

    /// Get multiple attributes in a single IPC call for performance
    func attributes(_ names: [String]) throws -> [String: Any] {
        var values: CFArray?
        let result = AXUIElementCopyMultipleAttributeValues(
            axElement,
            names as CFArray,
            .stopOnError,
            &values
        )

        guard result == .success, let values = values as? [Any] else {
            // Fall back to individual fetches
            var dict: [String: Any] = [:]
            for name in names {
                if let value: Any = try attribute(name) {
                    dict[name] = value
                }
            }
            return dict
        }

        var dict: [String: Any] = [:]
        for (index, name) in names.enumerated() {
            guard index < values.count else { break }
            let value = values[index]
            // Skip AXError values (returned for missing attributes)
            if CFGetTypeID(value as CFTypeRef) != AXValueGetTypeID() {
                if let cfError = value as? Int, cfError < 0 {
                    continue
                }
            }
            if let unpacked = unpackValue(value as CFTypeRef) {
                dict[name] = unpacked
            }
        }
        return dict
    }

    /// Get the list of available attribute names
    func attributeNames() throws -> [String] {
        var names: CFArray?
        let result = AXUIElementCopyAttributeNames(axElement, &names)

        guard result == .success, let names = names as? [String] else {
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            return []
        }
        return names
    }

    /// Get the count of an array attribute
    func attributeCount(_ name: String) throws -> Int {
        var count: CFIndex = 0
        let result = AXUIElementGetAttributeValueCount(axElement, name as CFString, &count)

        guard result == .success else {
            if result == .attributeUnsupported || result == .noValue {
                return 0
            }
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            return 0
        }
        return count
    }

    // MARK: - Common Attributes

    var role: String? {
        try? attribute(kAXRoleAttribute)
    }

    var subrole: String? {
        try? attribute(kAXSubroleAttribute)
    }

    var roleDescription: String? {
        try? attribute(kAXRoleDescriptionAttribute)
    }

    var title: String? {
        try? attribute(kAXTitleAttribute)
    }

    var description: String? {
        try? attribute(kAXDescriptionAttribute)
    }

    var value: Any? {
        try? attribute(kAXValueAttribute)
    }

    var stringValue: String? {
        value as? String
    }

    var position: CGPoint? {
        try? attribute(kAXPositionAttribute)
    }

    var size: CGSize? {
        try? attribute(kAXSizeAttribute)
    }

    var frame: CGRect? {
        guard let position = position, let size = size else { return nil }
        return CGRect(origin: position, size: size)
    }

    var isEnabled: Bool {
        (try? attribute(kAXEnabledAttribute)) ?? false
    }

    var isFocused: Bool {
        (try? attribute(kAXFocusedAttribute)) ?? false
    }

    var identifier: String? {
        try? attribute(kAXIdentifierAttribute)
    }

    var help: String? {
        try? attribute(kAXHelpAttribute)
    }

    var parent: Element? {
        guard let element: AXUIElement = try? attribute(kAXParentAttribute) else {
            return nil
        }
        return Element(element)
    }

    var children: [Element] {
        guard let elements: [AXUIElement] = try? attribute(kAXChildrenAttribute) else {
            return []
        }
        return elements.map { Element($0) }
    }

    var windows: [Element] {
        guard let elements: [AXUIElement] = try? attribute(kAXWindowsAttribute) else {
            return []
        }
        return elements.map { Element($0) }
    }

    var focusedWindow: Element? {
        guard let element: AXUIElement = try? attribute(kAXFocusedWindowAttribute) else {
            return nil
        }
        return Element(element)
    }

    var mainWindow: Element? {
        guard let element: AXUIElement = try? attribute(kAXMainWindowAttribute) else {
            return nil
        }
        return Element(element)
    }

    var pid: pid_t? {
        var pid: pid_t = 0
        let result = AXUIElementGetPid(axElement, &pid)
        return result == .success ? pid : nil
    }

    // MARK: - Actions

    /// Get the list of available actions
    func actionNames() throws -> [String] {
        var names: CFArray?
        let result = AXUIElementCopyActionNames(axElement, &names)

        guard result == .success, let names = names as? [String] else {
            if result == .attributeUnsupported || result == .noValue {
                return []
            }
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            return []
        }
        return names
    }

    /// Perform an action on the element
    func performAction(_ name: String) throws {
        let result = AXUIElementPerformAction(axElement, name as CFString)

        guard result == .success else {
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            throw AXError.actionFailed("Unknown error performing \(name)")
        }
    }

    /// Set an attribute value
    func setAttribute(_ name: String, value: Any) throws {
        let cfValue = packValue(value)
        let result = AXUIElementSetAttributeValue(axElement, name as CFString, cfValue)

        guard result == .success else {
            if let code = AXError.Code(rawValue: result.rawValue) {
                throw AXError.apiError(code)
            }
            throw AXError.actionFailed("Failed to set \(name)")
        }
    }

    // MARK: - Value Packing/Unpacking

    /// Unpack AXValue types (CGPoint, CGSize, CGRect, CFRange) and other CF types
    private func unpackValue(_ value: CFTypeRef) -> Any? {
        let typeID = CFGetTypeID(value)

        // Handle AXValue (wraps CGPoint, CGSize, CGRect, CFRange)
        if typeID == AXValueGetTypeID() {
            let axValue = value as! AXValue
            let axType = AXValueGetType(axValue)

            switch axType {
            case .cgPoint:
                var point = CGPoint.zero
                if AXValueGetValue(axValue, .cgPoint, &point) {
                    return point
                }
            case .cgSize:
                var size = CGSize.zero
                if AXValueGetValue(axValue, .cgSize, &size) {
                    return size
                }
            case .cgRect:
                var rect = CGRect.zero
                if AXValueGetValue(axValue, .cgRect, &rect) {
                    return rect
                }
            case .cfRange:
                var range = CFRange(location: 0, length: 0)
                if AXValueGetValue(axValue, .cfRange, &range) {
                    return range
                }
            default:
                break
            }
            return nil
        }

        // Handle AXUIElement
        if typeID == AXUIElementGetTypeID() {
            return value as! AXUIElement
        }

        // Handle arrays
        if typeID == CFArrayGetTypeID() {
            let array = value as! [Any]
            return array.compactMap { unpackValue($0 as CFTypeRef) }
        }

        // Handle standard CF types - let Swift bridge them
        return value
    }

    /// Pack values for setting attributes
    private func packValue(_ value: Any) -> CFTypeRef {
        switch value {
        case let point as CGPoint:
            var p = point
            return AXValueCreate(.cgPoint, &p)!
        case let size as CGSize:
            var s = size
            return AXValueCreate(.cgSize, &s)!
        case let rect as CGRect:
            var r = rect
            return AXValueCreate(.cgRect, &r)!
        case let range as CFRange:
            var r = range
            return AXValueCreate(.cfRange, &r)!
        default:
            return value as CFTypeRef
        }
    }

    // MARK: - Timeout

    /// Set the messaging timeout for this element
    func setTimeout(_ seconds: Float) {
        AXUIElementSetMessagingTimeout(axElement, seconds)
    }
}

// MARK: - Equatable

extension Element: Equatable {
    static func == (lhs: Element, rhs: Element) -> Bool {
        return CFEqual(lhs.axElement, rhs.axElement)
    }
}

// MARK: - Hashable

extension Element: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(axElement))
    }
}
