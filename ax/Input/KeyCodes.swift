//
//  KeyCodes.swift
//  ax
//
//  Virtual key code mapping for keyboard simulation.
//
//  Key codes are from Carbon.HIToolbox (kVK_* constants). These are
//  hardware-level codes independent of keyboard layout. For example,
//  kVK_ANSI_A is always the physical 'A' key position on ANSI keyboards,
//  regardless of what character it types in different layouts.
//
//  Supported key names:
//  - Letters: a-z
//  - Numbers: 0-9 (top row, not keypad)
//  - Function keys: f1-f20
//  - Navigation: up, down, left, right, pageup, pagedown, home, end
//  - Editing: return/enter, tab, space, delete/backspace, forwarddelete, escape/esc
//  - Modifiers: cmd/command, shift, alt/option, ctrl/control, fn
//  - Keypad: keypad0-9, keypadclear, keypaddecimal, etc.
//  - Punctuation: minus, equal, comma, period, slash, backslash, etc.
//

import Foundation
import Carbon.HIToolbox

/// Mapping from key names to virtual key codes
struct KeyCodes {

    /// Get the virtual key code for a key name
    static func code(for name: String) -> CGKeyCode? {
        let lower = name.lowercased()

        // Check special keys first
        if let code = specialKeys[lower] {
            return CGKeyCode(code)
        }

        // Check single character keys
        if name.count == 1, let code = characterKeys[lower] {
            return CGKeyCode(code)
        }

        // Check numeric keys (0-9)
        if let num = Int(name), num >= 0 && num <= 9 {
            return CGKeyCode(numberKeys[num])
        }

        return nil
    }

    // MARK: - Key Code Tables

    /// Special keys (function keys, modifiers, etc.)
    private static let specialKeys: [String: Int] = [
        // Function keys
        "f1": kVK_F1,
        "f2": kVK_F2,
        "f3": kVK_F3,
        "f4": kVK_F4,
        "f5": kVK_F5,
        "f6": kVK_F6,
        "f7": kVK_F7,
        "f8": kVK_F8,
        "f9": kVK_F9,
        "f10": kVK_F10,
        "f11": kVK_F11,
        "f12": kVK_F12,
        "f13": kVK_F13,
        "f14": kVK_F14,
        "f15": kVK_F15,
        "f16": kVK_F16,
        "f17": kVK_F17,
        "f18": kVK_F18,
        "f19": kVK_F19,
        "f20": kVK_F20,

        // Navigation
        "up": kVK_UpArrow,
        "down": kVK_DownArrow,
        "left": kVK_LeftArrow,
        "right": kVK_RightArrow,
        "pageup": kVK_PageUp,
        "pagedown": kVK_PageDown,
        "home": kVK_Home,
        "end": kVK_End,

        // Editing
        "return": kVK_Return,
        "enter": kVK_Return,
        "tab": kVK_Tab,
        "space": kVK_Space,
        "delete": kVK_Delete,
        "backspace": kVK_Delete,
        "forwarddelete": kVK_ForwardDelete,
        "escape": kVK_Escape,
        "esc": kVK_Escape,

        // Modifiers (for reference, usually used as modifiers not keys)
        "command": kVK_Command,
        "cmd": kVK_Command,
        "shift": kVK_Shift,
        "option": kVK_Option,
        "alt": kVK_Option,
        "control": kVK_Control,
        "ctrl": kVK_Control,
        "capslock": kVK_CapsLock,
        "fn": kVK_Function,

        // Keypad
        "keypad0": kVK_ANSI_Keypad0,
        "keypad1": kVK_ANSI_Keypad1,
        "keypad2": kVK_ANSI_Keypad2,
        "keypad3": kVK_ANSI_Keypad3,
        "keypad4": kVK_ANSI_Keypad4,
        "keypad5": kVK_ANSI_Keypad5,
        "keypad6": kVK_ANSI_Keypad6,
        "keypad7": kVK_ANSI_Keypad7,
        "keypad8": kVK_ANSI_Keypad8,
        "keypad9": kVK_ANSI_Keypad9,
        "keypadclear": kVK_ANSI_KeypadClear,
        "keypaddecimal": kVK_ANSI_KeypadDecimal,
        "keypaddivide": kVK_ANSI_KeypadDivide,
        "keypadenter": kVK_ANSI_KeypadEnter,
        "keypadequals": kVK_ANSI_KeypadEquals,
        "keypadminus": kVK_ANSI_KeypadMinus,
        "keypadmultiply": kVK_ANSI_KeypadMultiply,
        "keypadplus": kVK_ANSI_KeypadPlus,

        // Media keys (require special handling on some systems)
        "volumeup": kVK_VolumeUp,
        "volumedown": kVK_VolumeDown,
        "mute": kVK_Mute,

        // Help key
        "help": kVK_Help,
    ]

    /// Letter and punctuation keys (ANSI layout)
    private static let characterKeys: [String: Int] = [
        // Letters
        "a": kVK_ANSI_A,
        "b": kVK_ANSI_B,
        "c": kVK_ANSI_C,
        "d": kVK_ANSI_D,
        "e": kVK_ANSI_E,
        "f": kVK_ANSI_F,
        "g": kVK_ANSI_G,
        "h": kVK_ANSI_H,
        "i": kVK_ANSI_I,
        "j": kVK_ANSI_J,
        "k": kVK_ANSI_K,
        "l": kVK_ANSI_L,
        "m": kVK_ANSI_M,
        "n": kVK_ANSI_N,
        "o": kVK_ANSI_O,
        "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q,
        "r": kVK_ANSI_R,
        "s": kVK_ANSI_S,
        "t": kVK_ANSI_T,
        "u": kVK_ANSI_U,
        "v": kVK_ANSI_V,
        "w": kVK_ANSI_W,
        "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y,
        "z": kVK_ANSI_Z,

        // Punctuation
        "-": kVK_ANSI_Minus,
        "minus": kVK_ANSI_Minus,
        "=": kVK_ANSI_Equal,
        "equal": kVK_ANSI_Equal,
        "equals": kVK_ANSI_Equal,
        "[": kVK_ANSI_LeftBracket,
        "leftbracket": kVK_ANSI_LeftBracket,
        "]": kVK_ANSI_RightBracket,
        "rightbracket": kVK_ANSI_RightBracket,
        "'": kVK_ANSI_Quote,
        "quote": kVK_ANSI_Quote,
        ";": kVK_ANSI_Semicolon,
        "semicolon": kVK_ANSI_Semicolon,
        "\\": kVK_ANSI_Backslash,
        "backslash": kVK_ANSI_Backslash,
        ",": kVK_ANSI_Comma,
        "comma": kVK_ANSI_Comma,
        "/": kVK_ANSI_Slash,
        "slash": kVK_ANSI_Slash,
        ".": kVK_ANSI_Period,
        "period": kVK_ANSI_Period,
        "`": kVK_ANSI_Grave,
        "grave": kVK_ANSI_Grave,
        "backtick": kVK_ANSI_Grave,
    ]

    /// Number keys (top row, not keypad)
    private static let numberKeys: [Int] = [
        kVK_ANSI_0,
        kVK_ANSI_1,
        kVK_ANSI_2,
        kVK_ANSI_3,
        kVK_ANSI_4,
        kVK_ANSI_5,
        kVK_ANSI_6,
        kVK_ANSI_7,
        kVK_ANSI_8,
        kVK_ANSI_9,
    ]
}
