//
//  AddressResolver.swift
//  ax
//
//  Resolves Address values to concrete points, rects, or elements.
//
//  Resolution Process:
//  - Absolute addresses (@x,y) resolve directly to coordinates
//  - Element addresses require looking up the element and getting its position
//  - Offset addresses add the offset to the element's origin
//  - Rect addresses extend a point by the specified size
//

import Foundation
import ApplicationServices
import AppKit
import CoreGraphics

/// Result of resolving an address to a point
struct ResolvedPoint {
    let x: Int
    let y: Int
    let element: Element?  // Source element if address was element-based

    var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

/// Result of resolving an address to a rect
struct ResolvedRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let element: Element?  // Source element if address was element-based

    var cgRect: CGRect {
        CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
}

/// Resolves Address values to concrete coordinates and elements
struct AddressResolver {

    // MARK: - Resolve to Point

    /// Resolve an address to a screen point
    /// For elements, uses the element's origin (top-left corner)
    /// For element offsets, adds the offset to the element's origin
    static func resolvePoint(_ address: Address) throws -> ResolvedPoint {
        switch address {
        case .absolutePoint(let x, let y):
            return ResolvedPoint(x: x, y: y, element: nil)

        case .absoluteRect(let x, let y, _, _):
            // Use origin of rect as point
            return ResolvedPoint(x: x, y: y, element: nil)

        case .element(let pid, let hash):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedPoint(x: Int(origin.x), y: Int(origin.y), element: element)

        case .elementRect(let pid, let hash, _, _):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedPoint(x: Int(origin.x), y: Int(origin.y), element: element)

        case .elementOffset(let pid, let hash, let dx, let dy):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedPoint(x: Int(origin.x) + dx, y: Int(origin.y) + dy, element: element)

        case .elementOffsetRect(let pid, let hash, let dx, let dy, _, _):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedPoint(x: Int(origin.x) + dx, y: Int(origin.y) + dy, element: element)

        case .pid:
            throw AXError.invalidArguments("Cannot resolve PID to a point")
        }
    }

    // MARK: - Resolve to Rect

    /// Resolve an address to a screen rect
    /// For elements without explicit size, uses the element's frame
    /// For addresses with +WxH, uses that size
    static func resolveRect(_ address: Address) throws -> ResolvedRect {
        switch address {
        case .absolutePoint(let x, let y):
            // Point without size - return 1x1 rect
            return ResolvedRect(x: x, y: y, width: 1, height: 1, element: nil)

        case .absoluteRect(let x, let y, let width, let height):
            return ResolvedRect(x: x, y: y, width: width, height: height, element: nil)

        case .element(let pid, let hash):
            let element = try lookupElement(pid: pid, hash: hash)
            guard let frame = element.frame else {
                throw AXError.notFound("Element has no frame")
            }
            return ResolvedRect(
                x: Int(frame.origin.x),
                y: Int(frame.origin.y),
                width: Int(frame.size.width),
                height: Int(frame.size.height),
                element: element
            )

        case .elementRect(let pid, let hash, let width, let height):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedRect(
                x: Int(origin.x),
                y: Int(origin.y),
                width: width,
                height: height,
                element: element
            )

        case .elementOffset(let pid, let hash, let dx, let dy):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            // Offset without size - return 1x1 rect
            return ResolvedRect(
                x: Int(origin.x) + dx,
                y: Int(origin.y) + dy,
                width: 1,
                height: 1,
                element: element
            )

        case .elementOffsetRect(let pid, let hash, let dx, let dy, let width, let height):
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return ResolvedRect(
                x: Int(origin.x) + dx,
                y: Int(origin.y) + dy,
                width: width,
                height: height,
                element: element
            )

        case .pid:
            throw AXError.invalidArguments("Cannot resolve PID to a rect")
        }
    }

    // MARK: - Resolve to Element

    /// Resolve an address to an Element
    /// For absolute coordinates, finds the element at that screen position
    /// For element addresses, looks up the element by ID
    static func resolveElement(_ address: Address) throws -> Element {
        switch address {
        case .absolutePoint(let x, let y):
            return try elementAtPoint(x: x, y: y)

        case .absoluteRect(let x, let y, _, _):
            // Use origin of rect to find element
            return try elementAtPoint(x: x, y: y)

        case .element(let pid, let hash):
            return try lookupElement(pid: pid, hash: hash)

        case .elementRect(let pid, let hash, _, _):
            return try lookupElement(pid: pid, hash: hash)

        case .elementOffset(let pid, let hash, let dx, let dy):
            // Get element at the offset position
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return try elementAtPoint(x: Int(origin.x) + dx, y: Int(origin.y) + dy)

        case .elementOffsetRect(let pid, let hash, let dx, let dy, _, _):
            // Get element at the offset position
            let element = try lookupElement(pid: pid, hash: hash)
            let origin = try getElementOrigin(element)
            return try elementAtPoint(x: Int(origin.x) + dx, y: Int(origin.y) + dy)

        case .pid(let pid):
            return Element.application(pid: pid)
        }
    }

    // MARK: - Resolve to Application

    /// Resolve an address to an application Element
    /// For element addresses, returns the app that owns the element
    static func resolveApplication(_ address: Address) throws -> Element {
        switch address {
        case .pid(let pid):
            return Element.application(pid: pid)

        case .element(let pid, _),
             .elementRect(let pid, _, _, _),
             .elementOffset(let pid, _, _, _),
             .elementOffsetRect(let pid, _, _, _, _, _):
            return Element.application(pid: pid)

        case .absolutePoint, .absoluteRect:
            throw AXError.invalidArguments("Cannot resolve coordinates to an application")
        }
    }

    // MARK: - Private Helpers

    /// Look up an element by PID and hash
    private static func lookupElement(pid: pid_t, hash: CFHashCode) throws -> Element {
        let id = "\(pid):\(hash)"
        guard let axElement = ElementRegistry.shared.lookup(id) else {
            throw AXError.notFound("Element \(id)")
        }
        return Element(axElement)
    }

    /// Get the screen-relative origin of an element
    /// This is the element's position attribute, which is in screen coordinates
    private static func getElementOrigin(_ element: Element) throws -> CGPoint {
        guard let position = element.position else {
            throw AXError.notFound("Element has no position")
        }
        return position
    }

    /// Find the element at a screen position
    private static func elementAtPoint(x: Int, y: Int) throws -> Element {
        let point = CGPoint(x: CGFloat(x), y: CGFloat(y))

        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw AXError.notFound("No frontmost application")
        }

        let app = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Use AXUIElementCopyElementAtPosition to find element
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(app, Float(point.x), Float(point.y), &element)

        guard result == .success, let element = element else {
            // Try system-wide element as fallback
            let systemWide = AXUIElementCreateSystemWide()
            var systemElement: AXUIElement?
            let sysResult = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &systemElement)

            guard sysResult == .success, let foundElement = systemElement else {
                throw AXError.notFound("No element at position (\(x), \(y))")
            }
            return Element(foundElement)
        }

        return Element(element)
    }
}

// MARK: - Elements in Rect

extension AddressResolver {

    /// Find all elements within a screen rect
    /// Returns elements whose frames intersect with the given rect
    static func elementsInRect(_ rect: ResolvedRect) throws -> [Element] {
        let cgRect = rect.cgRect
        var foundElements: [Element] = []

        // Get all running apps
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for app in apps {
            let appElement = Element.application(pid: app.processIdentifier)

            // Get windows
            for window in appElement.windows {
                if let frame = window.frame, cgRect.intersects(frame) {
                    foundElements.append(window)
                    // Also check children of the window
                    foundElements.append(contentsOf: try elementsInRectRecursive(window, rect: cgRect, maxDepth: 10))
                }
            }
        }

        return foundElements
    }

    /// Recursively find elements within a rect
    private static func elementsInRectRecursive(_ element: Element, rect: CGRect, maxDepth: Int) throws -> [Element] {
        guard maxDepth > 0 else { return [] }

        var found: [Element] = []

        for child in element.children {
            if let frame = child.frame, rect.intersects(frame) {
                found.append(child)
                found.append(contentsOf: try elementsInRectRecursive(child, rect: rect, maxDepth: maxDepth - 1))
            }
        }

        return found
    }
}
