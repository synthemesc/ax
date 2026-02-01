//
//  AXNameFormatter.swift
//  ax
//
//  Centralized formatting for AX names.
//
//  Converts between:
//  - Internal AX names: "AXStaticText", "AXShowMenu", "AXCloseButton"
//  - Display names: "static_text", "show_menu", "close_button"
//
//  Display format is lowercase with underscores (snake_case), which is:
//  - Easier to read and type
//  - Consistent with JSON conventions
//  - AI-agent-friendly (no prefix to strip)
//

import Foundation

/// Centralized formatting for accessibility names (roles, subroles, actions)
struct AXNameFormatter {

    /// Convert AX name to display format
    /// "AXStaticText" → "static_text"
    /// "AXShowMenu" → "show_menu"
    /// "AXCloseButton" → "close_button"
    static func formatForDisplay(_ name: String) -> String {
        var result = name

        // Strip "AX" prefix
        if result.hasPrefix("AX") {
            result = String(result.dropFirst(2))
        }

        // Convert PascalCase to snake_case
        return toSnakeCase(result)
    }

    /// Convert display name to AX API format
    /// "static_text" → "AXStaticText"
    /// "show_menu" → "AXShowMenu"
    /// "press" → "AXPress"
    static func formatForAPI(_ name: String) -> String {
        // If already has AX prefix, use as-is
        if name.hasPrefix("AX") {
            return name
        }

        // Convert snake_case to PascalCase and add AX prefix
        let pascalCase = toPascalCase(name)
        return "AX" + pascalCase
    }

    // MARK: - Private Helpers

    /// Convert PascalCase to snake_case
    /// "StaticText" → "static_text"
    /// "ShowMenu" → "show_menu"
    private static func toSnakeCase(_ input: String) -> String {
        guard !input.isEmpty else { return input }

        var result = ""
        var previousWasLower = false

        for char in input {
            if char.isUppercase {
                if previousWasLower {
                    result += "_"
                }
                result += char.lowercased()
                previousWasLower = false
            } else {
                result += String(char)
                previousWasLower = char.isLetter
            }
        }

        return result
    }

    /// Convert snake_case or camelCase to PascalCase
    /// "static_text" → "StaticText"
    /// "showMenu" → "ShowMenu"
    /// "press" → "Press"
    private static func toPascalCase(_ input: String) -> String {
        // Handle snake_case
        if input.contains("_") {
            return input.split(separator: "_")
                .map { String($0).prefix(1).uppercased() + String($0).dropFirst() }
                .joined()
        }

        // Handle camelCase or single word - just capitalize first letter
        if let first = input.first {
            return first.uppercased() + input.dropFirst()
        }

        return input
    }
}
