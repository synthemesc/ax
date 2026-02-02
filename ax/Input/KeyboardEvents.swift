//
//  KeyboardEvents.swift
//  ax
//

import Foundation
import CoreGraphics
import Carbon.HIToolbox

/// Keyboard event utilities using CGEvent
struct KeyboardEvents {

    /// Marker value to identify ax-generated events (allows them to pass through event taps)
    static let eventMarker: Int64 = 0x4158304158  // "AX0AX" in hex

    /// Create an event source with our marker value
    private static func markedSource() -> CGEventSource? {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return nil
        }
        source.userData = eventMarker
        return source
    }

    /// Type a string of text using Unicode input
    static func type(_ text: String) {
        for char in text {
            typeCharacter(char)
        }
    }

    /// Type a single character
    private static func typeCharacter(_ char: Character) {
        let utf16 = Array(String(char).utf16)
        let source = markedSource()

        guard let downEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let upEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return
        }

        downEvent.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        upEvent.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    /// Press a key combination (e.g., cmd+shift+s)
    static func pressKey(_ combo: String) throws {
        let parts = combo.lowercased().split(separator: "+")

        var modifiers: CGEventFlags = []
        var keyCode: CGKeyCode?

        for part in parts {
            let key = String(part).trimmingCharacters(in: .whitespaces)

            switch key {
            case "cmd", "command", "meta":
                modifiers.insert(.maskCommand)
            case "shift":
                modifiers.insert(.maskShift)
            case "alt", "option", "opt":
                modifiers.insert(.maskAlternate)
            case "ctrl", "control":
                modifiers.insert(.maskControl)
            case "fn", "function":
                modifiers.insert(.maskSecondaryFn)
            default:
                // It's a key name
                guard let code = KeyCodes.code(for: key) else {
                    throw AXError.invalidArguments("Unknown key: \(key)")
                }
                keyCode = code
            }
        }

        guard let code = keyCode else {
            throw AXError.invalidArguments("No key specified in combo: \(combo)")
        }

        pressKey(code: code, modifiers: modifiers)
    }

    /// Press a key with optional modifiers
    static func pressKey(code: CGKeyCode, modifiers: CGEventFlags = []) {
        let source = markedSource()
        guard let downEvent = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
              let upEvent = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else {
            return
        }

        downEvent.flags = modifiers
        upEvent.flags = modifiers

        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    /// Press a key multiple times
    static func pressKey(_ combo: String, repeatCount: Int) throws {
        for _ in 0..<repeatCount {
            try pressKey(combo)
            // Small delay between repeats
            usleep(10000)  // 10ms
        }
    }

    /// Hold down modifier keys, execute a block, then release
    static func withModifiers(_ modifiers: CGEventFlags, execute: () -> Void) {
        // Press modifier keys
        if modifiers.contains(.maskCommand) {
            pressKeyDown(code: CGKeyCode(kVK_Command))
        }
        if modifiers.contains(.maskShift) {
            pressKeyDown(code: CGKeyCode(kVK_Shift))
        }
        if modifiers.contains(.maskAlternate) {
            pressKeyDown(code: CGKeyCode(kVK_Option))
        }
        if modifiers.contains(.maskControl) {
            pressKeyDown(code: CGKeyCode(kVK_Control))
        }

        execute()

        // Release modifier keys
        if modifiers.contains(.maskControl) {
            pressKeyUp(code: CGKeyCode(kVK_Control))
        }
        if modifiers.contains(.maskAlternate) {
            pressKeyUp(code: CGKeyCode(kVK_Option))
        }
        if modifiers.contains(.maskShift) {
            pressKeyUp(code: CGKeyCode(kVK_Shift))
        }
        if modifiers.contains(.maskCommand) {
            pressKeyUp(code: CGKeyCode(kVK_Command))
        }
    }

    private static func pressKeyDown(code: CGKeyCode) {
        let source = markedSource()
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true) else { return }
        event.post(tap: .cghidEventTap)
    }

    private static func pressKeyUp(code: CGKeyCode) {
        let source = markedSource()
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else { return }
        event.post(tap: .cghidEventTap)
    }
}
