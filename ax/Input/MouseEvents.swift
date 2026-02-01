//
//  MouseEvents.swift
//  ax
//

import Foundation
import CoreGraphics

/// Mouse event utilities using CGEvent
struct MouseEvents {

    enum Button {
        case left
        case right
        case center
    }

    /// Click at a screen position
    static func click(at point: CGPoint, button: Button = .left) {
        let (downType, upType, cgButton) = eventTypes(for: button)

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: cgButton) else {
            return
        }
        guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: cgButton) else {
            return
        }

        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    /// Double-click at a screen position
    static func doubleClick(at point: CGPoint, button: Button = .left) {
        let (downType, upType, cgButton) = eventTypes(for: button)

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: cgButton) else {
            return
        }
        guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: cgButton) else {
            return
        }

        // First click
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)

        // Second click with click count = 2
        downEvent.setIntegerValueField(.mouseEventClickState, value: 2)
        upEvent.setIntegerValueField(.mouseEventClickState, value: 2)
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    /// Move mouse to a position
    static func move(to point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    /// Drag from one position to another
    static func drag(from start: CGPoint, to end: CGPoint, button: Button = .left) {
        let (downType, upType, cgButton) = eventTypes(for: button)
        let dragType: CGEventType = button == .left ? .leftMouseDragged : .rightMouseDragged

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: start, mouseButton: cgButton) else {
            return
        }
        guard let dragEvent = CGEvent(mouseEventSource: nil, mouseType: dragType, mouseCursorPosition: end, mouseButton: cgButton) else {
            return
        }
        guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: end, mouseButton: cgButton) else {
            return
        }

        downEvent.post(tap: .cghidEventTap)
        dragEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    /// Get the current mouse position
    static var currentPosition: CGPoint {
        return CGEvent(source: nil)?.location ?? .zero
    }

    // MARK: - Private

    private static func eventTypes(for button: Button) -> (down: CGEventType, up: CGEventType, button: CGMouseButton) {
        switch button {
        case .left:
            return (.leftMouseDown, .leftMouseUp, .left)
        case .right:
            return (.rightMouseDown, .rightMouseUp, .right)
        case .center:
            return (.otherMouseDown, .otherMouseUp, .center)
        }
    }
}
