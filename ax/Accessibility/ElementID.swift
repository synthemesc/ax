//
//  ElementID.swift
//  ax
//
//  Element ID system for referencing AXUIElements.
//
//  IMPORTANT LIMITATION:
//  Element IDs are hex-encoded memory addresses of AXUIElement pointers.
//  They are ONLY valid within a single process execution. An ID from
//  `ax ls 1234` cannot be used in a subsequent `ax click 0x...` call
//  because the AXUIElement is released when the first process exits.
//
//  The ElementRegistry keeps elements alive during a command by storing
//  strong references. This allows chained operations within one session
//  but not across separate invocations.
//
//  Future enhancement: Consider serializing element paths (e.g., window
//  index + child indices) for cross-process references.
//

import Foundation
import ApplicationServices

/// Registry that keeps AXUIElement references alive during command execution.
/// Element IDs are hex-encoded pointers that allow elements to be referenced across commands.
final class ElementRegistry {
    static let shared = ElementRegistry()

    private var elements: [String: AXUIElement] = [:]
    private let lock = NSLock()

    private init() {}

    /// Register an element and return its ID
    func register(_ element: AXUIElement) -> String {
        let id = Self.makeID(element)
        lock.lock()
        elements[id] = element
        lock.unlock()
        return id
    }

    /// Look up an element by ID
    func lookup(_ id: String) -> AXUIElement? {
        lock.lock()
        defer { lock.unlock() }
        return elements[id]
    }

    /// Clear all registered elements
    func clear() {
        lock.lock()
        elements.removeAll()
        lock.unlock()
    }

    /// Create an ID from an AXUIElement (hex pointer)
    static func makeID(_ element: AXUIElement) -> String {
        let pointer = Unmanaged.passUnretained(element).toOpaque()
        return String(format: "0x%llx", UInt64(UInt(bitPattern: pointer)))
    }

    /// Parse an element ID (hex string) - returns the numeric value
    static func parseID(_ id: String) -> UInt64? {
        var hexString = id
        if hexString.hasPrefix("0x") || hexString.hasPrefix("0X") {
            hexString = String(hexString.dropFirst(2))
        }
        return UInt64(hexString, radix: 16)
    }
}
