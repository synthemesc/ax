//
//  KeysDoc.swift
//  ax
//
//  Documentation for key names used with ax key.
//

import Foundation

/// Documentation for key names
struct KeysDoc {

    static let text = """
KEY NAMES

Key names for use with 'ax key <combo>':

MODIFIERS (combine with + )
  cmd, command      Command key
  shift             Shift key
  alt, option       Option/Alt key
  ctrl, control     Control key
  fn                Function key

EXAMPLES
  ax key cmd+s            # Cmd+S (save)
  ax key cmd+shift+z      # Cmd+Shift+Z (redo)
  ax key cmd+alt+esc      # Cmd+Option+Escape (force quit)
  ax key ctrl+c           # Ctrl+C
  ax key return           # Return/Enter
  ax key space            # Spacebar
  ax key tab              # Tab
  ax key up --repeat 5    # Press up arrow 5 times

LETTERS
  a-z               Letter keys (case insensitive)

NUMBERS
  0-9               Number row (not keypad)

FUNCTION KEYS
  f1-f20            Function keys

NAVIGATION
  up, down          Arrow keys
  left, right
  pageup, pagedown  Page Up/Down
  home, end         Home/End

EDITING
  return, enter     Return/Enter key
  tab               Tab key
  space             Spacebar
  delete, backspace Backspace/Delete
  forwarddelete     Forward Delete
  escape, esc       Escape key

PUNCTUATION
  minus, -          Minus/hyphen
  equal, equals, =  Equals
  leftbracket, [    Left bracket
  rightbracket, ]   Right bracket
  backslash, \\      Backslash
  semicolon, ;      Semicolon
  quote, '          Single quote
  comma, ,          Comma
  period, .         Period
  slash, /          Forward slash
  grave, `, backtick Backtick/grave accent

KEYPAD
  keypad0-9         Keypad numbers
  keypadclear       Keypad clear
  keypaddecimal     Keypad decimal point
  keypaddivide      Keypad divide
  keypadenter       Keypad enter
  keypadequals      Keypad equals
  keypadminus       Keypad minus
  keypadmultiply    Keypad multiply
  keypadplus        Keypad plus

MEDIA
  volumeup          Volume up
  volumedown        Volume down
  mute              Mute

NOTES
- Modifier order doesn't matter: cmd+shift+s = shift+cmd+s
- Key names are case-insensitive
- Use --repeat N to press the key multiple times
"""

    static let entries: [KeyEntry] = [
        // Modifiers
        KeyEntry(name: "command", aliases: ["cmd"], description: "Command key"),
        KeyEntry(name: "shift", aliases: [], description: "Shift key"),
        KeyEntry(name: "option", aliases: ["alt"], description: "Option/Alt key"),
        KeyEntry(name: "control", aliases: ["ctrl"], description: "Control key"),
        KeyEntry(name: "fn", aliases: [], description: "Function key"),

        // Navigation
        KeyEntry(name: "up", aliases: [], description: "Up arrow"),
        KeyEntry(name: "down", aliases: [], description: "Down arrow"),
        KeyEntry(name: "left", aliases: [], description: "Left arrow"),
        KeyEntry(name: "right", aliases: [], description: "Right arrow"),
        KeyEntry(name: "pageup", aliases: [], description: "Page Up"),
        KeyEntry(name: "pagedown", aliases: [], description: "Page Down"),
        KeyEntry(name: "home", aliases: [], description: "Home key"),
        KeyEntry(name: "end", aliases: [], description: "End key"),

        // Editing
        KeyEntry(name: "return", aliases: ["enter"], description: "Return/Enter key"),
        KeyEntry(name: "tab", aliases: [], description: "Tab key"),
        KeyEntry(name: "space", aliases: [], description: "Spacebar"),
        KeyEntry(name: "delete", aliases: ["backspace"], description: "Backspace/Delete key"),
        KeyEntry(name: "forwarddelete", aliases: [], description: "Forward Delete key"),
        KeyEntry(name: "escape", aliases: ["esc"], description: "Escape key"),

        // Function keys
        KeyEntry(name: "f1", aliases: [], description: "F1 function key"),
        KeyEntry(name: "f2", aliases: [], description: "F2 function key"),
        KeyEntry(name: "f3", aliases: [], description: "F3 function key"),
        KeyEntry(name: "f4", aliases: [], description: "F4 function key"),
        KeyEntry(name: "f5", aliases: [], description: "F5 function key"),
        KeyEntry(name: "f6", aliases: [], description: "F6 function key"),
        KeyEntry(name: "f7", aliases: [], description: "F7 function key"),
        KeyEntry(name: "f8", aliases: [], description: "F8 function key"),
        KeyEntry(name: "f9", aliases: [], description: "F9 function key"),
        KeyEntry(name: "f10", aliases: [], description: "F10 function key"),
        KeyEntry(name: "f11", aliases: [], description: "F11 function key"),
        KeyEntry(name: "f12", aliases: [], description: "F12 function key"),

        // Punctuation
        KeyEntry(name: "minus", aliases: ["-"], description: "Minus/hyphen key"),
        KeyEntry(name: "equal", aliases: ["equals", "="], description: "Equals key"),
        KeyEntry(name: "leftbracket", aliases: ["["], description: "Left bracket"),
        KeyEntry(name: "rightbracket", aliases: ["]"], description: "Right bracket"),
        KeyEntry(name: "backslash", aliases: ["\\"], description: "Backslash"),
        KeyEntry(name: "semicolon", aliases: [";"], description: "Semicolon"),
        KeyEntry(name: "quote", aliases: ["'"], description: "Single quote"),
        KeyEntry(name: "comma", aliases: [","], description: "Comma"),
        KeyEntry(name: "period", aliases: ["."], description: "Period"),
        KeyEntry(name: "slash", aliases: ["/"], description: "Forward slash"),
        KeyEntry(name: "grave", aliases: ["`", "backtick"], description: "Backtick/grave accent"),
    ]
}
