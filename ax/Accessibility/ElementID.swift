//
//  ElementID.swift
//  ax
//
//  Stable element identification using CFHash.
//
//  CFHash returns the same value for AXUIElements that reference the same
//  underlying UI element, even across separate process invocations. This
//  allows element IDs from `ax ls` to be used in subsequent `ax click` calls.
//
//  ID Format: "<pid>:<hash>" e.g., "619:1668249066"
//  - PID identifies which app to search
//  - Hash identifies the specific element within that app
//
//  Lookup Strategy:
//  When given an ID, we walk the app's element tree to find the element
//  with matching CFHash. This is O(n) but typically fast for UI trees.
//

import Foundation
import ApplicationServices

/// Manages element ID generation and lookup using CFHash for stability.
struct ElementID {

    /// Create a stable ID for an element
    /// Format: "<pid>:<hash>"
    static func makeID(for element: AXUIElement) -> String? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else {
            return nil
        }
        let hash = CFHash(element)
        return "\(pid):\(hash)"
    }

    /// Parse an element ID into its components
    /// Returns (pid, hash) or nil if invalid format
    static func parse(_ id: String) -> (pid: pid_t, hash: CFHashCode)? {
        let parts = id.split(separator: ":")
        guard parts.count == 2,
              let pid = Int32(parts[0]),
              let hash = CFHashCode(parts[1]) else {
            return nil
        }
        return (pid, hash)
    }

    /// Look up an element by its ID
    /// Walks the element tree to find matching CFHash
    static func lookup(_ id: String) -> AXUIElement? {
        guard let (pid, targetHash) = parse(id) else {
            return nil
        }

        let app = AXUIElementCreateApplication(pid)

        // Check if it's the app element itself
        if CFHash(app) == targetHash {
            return app
        }

        // Search the element tree
        return findElement(in: app, withHash: targetHash, maxDepth: 50)
    }

    /// Recursively search for an element with matching hash
    private static func findElement(in element: AXUIElement, withHash targetHash: CFHashCode, maxDepth: Int) -> AXUIElement? {
        guard maxDepth > 0 else { return nil }

        // Get children
        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement] else {
            return nil
        }

        for child in children {
            // Check this child
            if CFHash(child) == targetHash {
                return child
            }

            // Recurse into child
            if let found = findElement(in: child, withHash: targetHash, maxDepth: maxDepth - 1) {
                return found
            }
        }

        // Also check windows (they're separate from children for apps)
        var windowsValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windowsValue) == .success,
           let windows = windowsValue as? [AXUIElement] {
            for window in windows {
                if CFHash(window) == targetHash {
                    return window
                }
                if let found = findElement(in: window, withHash: targetHash, maxDepth: maxDepth - 1) {
                    return found
                }
            }
        }

        return nil
    }

    /// Check if a string looks like an element ID (vs a PID)
    static func isElementID(_ string: String) -> Bool {
        return string.contains(":") && parse(string) != nil
    }
}

// MARK: - Legacy Registry (for within-session caching)

/// Registry that keeps AXUIElement references alive during command execution.
/// This improves performance by avoiding repeated tree walks for recent elements.
final class ElementRegistry {
    static let shared = ElementRegistry()

    private var elements: [String: AXUIElement] = [:]
    private let lock = NSLock()

    private init() {}

    /// Register an element and return its stable ID
    func register(_ element: AXUIElement) -> String {
        guard let id = ElementID.makeID(for: element) else {
            // Fallback to pointer-based ID if we can't get PID
            let pointer = Unmanaged.passUnretained(element).toOpaque()
            return String(format: "0x%llx", UInt64(UInt(bitPattern: pointer)))
        }

        lock.lock()
        elements[id] = element
        lock.unlock()

        return id
    }

    /// Look up an element by ID
    /// First checks cache, then falls back to tree search
    func lookup(_ id: String) -> AXUIElement? {
        lock.lock()
        if let cached = elements[id] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // Not in cache - search the tree
        if let found = ElementID.lookup(id) {
            // Cache for future lookups
            lock.lock()
            elements[id] = found
            lock.unlock()
            return found
        }

        return nil
    }

    /// Clear all cached elements
    func clear() {
        lock.lock()
        elements.removeAll()
        lock.unlock()
    }
}
