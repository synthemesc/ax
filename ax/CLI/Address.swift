//
//  Address.swift
//  ax
//
//  Universal addressing system for targeting points, rects, and elements.
//
//  Address Formats:
//    @x,y                    Absolute screen point
//    @x,y+WxH                Absolute screen rect
//    pid:hash                Element by ID
//    pid:hash+WxH            Rect from element's origin
//    pid:hash@dx,dy          Point offset from element's origin
//    pid:hash@dx,dy+WxH      Rect offset from element's origin
//    pid                     Application by PID
//
//  Operators:
//    @   Introduces coordinates (absolute if at start, offset if after element)
//    :   Separates PID from element hash
//    +   Extends a point into a rect with WxH size
//    x   Separates width from height in size specifier
//

import Foundation

/// A universal address that can represent points, rects, or elements
enum Address {
    /// Absolute screen point: @500,300
    case absolutePoint(x: Int, y: Int)

    /// Absolute screen rect: @100,200+400x300
    case absoluteRect(x: Int, y: Int, width: Int, height: Int)

    /// Element by ID: 1234:5678
    case element(pid: pid_t, hash: CFHashCode)

    /// Rect from element's origin: 1234:5678+400x300
    case elementRect(pid: pid_t, hash: CFHashCode, width: Int, height: Int)

    /// Point offset from element: 1234:5678@50,50
    case elementOffset(pid: pid_t, hash: CFHashCode, dx: Int, dy: Int)

    /// Rect offset from element: 1234:5678@50,50+400x300
    case elementOffsetRect(pid: pid_t, hash: CFHashCode, dx: Int, dy: Int, width: Int, height: Int)

    /// Application by PID: 1234
    case pid(pid_t)
}

/// Parser for universal address syntax
struct AddressParser {

    /// Parse an address string into an Address value
    static func parse(_ string: String) throws -> Address {
        let s = string.trimmingCharacters(in: .whitespaces)

        // Absolute coordinates start with @
        if s.hasPrefix("@") {
            return try parseAbsolute(String(s.dropFirst()))
        }

        // Element ID contains : (before any @)
        if let colonIndex = s.firstIndex(of: ":") {
            // Check if there's an @ after the :
            let afterColon = s[s.index(after: colonIndex)...]
            if afterColon.contains("@") || afterColon.contains("+") {
                return try parseElementWithModifiers(s)
            }
            // Plain element ID, possibly with +size
            if s.contains("+") {
                return try parseElementWithModifiers(s)
            }
            let (pid, hash) = try parseElementIDComponents(s)
            return .element(pid: pid, hash: hash)
        }

        // Bare integer is a PID
        if let pid = Int32(s) {
            return .pid(pid)
        }

        throw AXError.invalidArguments("Invalid address format: \(string)")
    }

    // MARK: - Private Parsing Helpers

    /// Parse absolute coordinates: x,y or x,y+WxH
    private static func parseAbsolute(_ s: String) throws -> Address {
        // Check for +size suffix
        if let plusIndex = s.firstIndex(of: "+") {
            let pointPart = String(s[..<plusIndex])
            let sizePart = String(s[s.index(after: plusIndex)...])

            let (x, y) = try parsePoint(pointPart)
            let (w, h) = try parseSize(sizePart)
            return .absoluteRect(x: x, y: y, width: w, height: h)
        }

        // Just a point
        let (x, y) = try parsePoint(s)
        return .absolutePoint(x: x, y: y)
    }

    /// Parse element ID with optional modifiers: pid:hash[@dx,dy][+WxH]
    private static func parseElementWithModifiers(_ s: String) throws -> Address {
        // Split into element ID and modifiers
        var remaining = s
        var offset: (dx: Int, dy: Int)?
        var size: (w: Int, h: Int)?

        // Extract +size if present (must be at end)
        if let plusIndex = remaining.lastIndex(of: "+") {
            let sizePart = String(remaining[remaining.index(after: plusIndex)...])
            // Only treat as size if it contains 'x' (to distinguish from negative numbers)
            if sizePart.contains("x") {
                let parsed = try parseSize(sizePart)
                size = (w: parsed.width, h: parsed.height)
                remaining = String(remaining[..<plusIndex])
            }
        }

        // Extract @offset if present
        if let atIndex = remaining.firstIndex(of: "@") {
            // Make sure @ is after : (not at start)
            if let colonIndex = remaining.firstIndex(of: ":"), atIndex > colonIndex {
                let offsetPart = String(remaining[remaining.index(after: atIndex)...])
                let parsed = try parsePoint(offsetPart)
                offset = (dx: parsed.x, dy: parsed.y)
                remaining = String(remaining[..<atIndex])
            }
        }

        // Parse the element ID
        let (pid, hash) = try parseElementIDComponents(remaining)

        // Build the appropriate Address type
        switch (offset, size) {
        case (nil, nil):
            return .element(pid: pid, hash: hash)
        case (nil, let (w, h)?):
            return .elementRect(pid: pid, hash: hash, width: w, height: h)
        case (let (dx, dy)?, nil):
            return .elementOffset(pid: pid, hash: hash, dx: dx, dy: dy)
        case (let (dx, dy)?, let (w, h)?):
            return .elementOffsetRect(pid: pid, hash: hash, dx: dx, dy: dy, width: w, height: h)
        }
    }

    /// Parse element ID: pid:hash -> (pid, hash)
    private static func parseElementIDComponents(_ s: String) throws -> (pid: pid_t, hash: CFHashCode) {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let pid = Int32(parts[0]),
              let hash = CFHashCode(parts[1]) else {
            throw AXError.invalidArguments("Invalid element ID: \(s). Expected format: pid:hash")
        }
        return (pid, hash)
    }

    /// Parse a point: x,y -> (x, y)
    private static func parsePoint(_ s: String) throws -> (x: Int, y: Int) {
        let parts = s.split(separator: ",")
        guard parts.count == 2,
              let x = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let y = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            throw AXError.invalidArguments("Invalid point: \(s). Expected format: x,y")
        }
        return (x, y)
    }

    /// Parse a size: WxH -> (width, height)
    private static func parseSize(_ s: String) throws -> (width: Int, height: Int) {
        // Split on 'x' (case insensitive)
        let lowercased = s.lowercased()
        let parts = lowercased.split(separator: "x")
        guard parts.count == 2,
              let w = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let h = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            throw AXError.invalidArguments("Invalid size: \(s). Expected format: WxH (e.g., 400x300)")
        }
        return (w, h)
    }
}

// MARK: - Address Convenience

extension Address {
    /// Check if this address refers to an element (vs absolute coordinates or PID)
    var isElement: Bool {
        switch self {
        case .element, .elementRect, .elementOffset, .elementOffsetRect:
            return true
        case .absolutePoint, .absoluteRect, .pid:
            return false
        }
    }

    /// Check if this address represents a rect (vs a point)
    var isRect: Bool {
        switch self {
        case .absoluteRect, .elementRect, .elementOffsetRect:
            return true
        case .absolutePoint, .element, .elementOffset, .pid:
            return false
        }
    }

    /// Get the element ID components if this is an element-based address
    var elementID: (pid: pid_t, hash: CFHashCode)? {
        switch self {
        case .element(let pid, let hash),
             .elementRect(let pid, let hash, _, _),
             .elementOffset(let pid, let hash, _, _),
             .elementOffsetRect(let pid, let hash, _, _, _, _):
            return (pid, hash)
        case .absolutePoint, .absoluteRect, .pid:
            return nil
        }
    }
}
