//
//  AttributesDoc.swift
//  ax
//
//  Documentation for output fields/attributes.
//

import Foundation

/// Documentation for element attributes/output fields
struct AttributesDoc {

    static let text = """
ELEMENT ATTRIBUTES

Fields returned in JSON output from 'ax ls':

IDENTITY
  id                string    Stable element ID in "pid-hash" format.
                              Use as target for click, action, focus commands.
                              Valid while app is running; changes on restart.

  role              string    Element type (button, window, text_field, etc.)
                              See 'ax help roles' for reference.

  subrole           string    Refinement of role (close_button, search_field, etc.)
                              May be null for many elements.

  identifier        string    Developer-set identifier for the element.
                              Useful for finding specific UI elements.
                              Often null; depends on app implementation.

CONTENT
  title             string    Window title or element label.
                              Primary text displayed to user.

  description       string    Accessibility description.
                              Additional context for screen readers.

  value             string    Current value of the element.
                              - Text field: current text content
                              - Checkbox: "0" or "1"
                              - Slider: numeric value as string
                              - Progress: percentage as string

  label             string    Human-readable role description.
                              Localized version of what the element is
                              (e.g., "button", "text field").

  help              string    Help text or tooltip content.
                              Contextual help for the element.

GEOMETRY
  frame             object    Element position and size on screen.
                              Contains: x, y, width, height
                              Coordinates are screen-relative (0,0 at top-left).

STATE
  enabled           boolean   Whether element accepts input.
                              Only present when false (disabled).

  focused           boolean   Whether element has keyboard focus.
                              Only present when true.

HIERARCHY
  actions           array     Available actions for this element.
                              List of strings like ["press", "show_menu"].
                              See 'ax help actions' for reference.

  children          array     Child elements (nested ElementInfo).
                              Controlled by --depth flag.
                              null when depth limit reached.

NOTES
- All fields except 'id' and 'role' may be null
- Fields with default values are omitted (enabled: true, focused: false)
- Use --depth to control how deep children are traversed
"""

    static let entries: [AttributeEntry] = [
        AttributeEntry(name: "id", type: "string", description: "Stable element ID in 'pid-hash' format. Use as target for click, action, focus commands."),
        AttributeEntry(name: "role", type: "string", description: "Element type (button, window, text_field, etc.)"),
        AttributeEntry(name: "subrole", type: "string?", description: "Refinement of role (close_button, search_field, etc.)"),
        AttributeEntry(name: "identifier", type: "string?", description: "Developer-set identifier for the element."),
        AttributeEntry(name: "title", type: "string?", description: "Window title or element label."),
        AttributeEntry(name: "description", type: "string?", description: "Accessibility description for screen readers."),
        AttributeEntry(name: "value", type: "string?", description: "Current value (text content, checkbox state, slider position)."),
        AttributeEntry(name: "label", type: "string?", description: "Human-readable role description (localized)."),
        AttributeEntry(name: "help", type: "string?", description: "Help text or tooltip content."),
        AttributeEntry(name: "frame", type: "object?", description: "Element position and size: {x, y, width, height}. Screen coordinates."),
        AttributeEntry(name: "enabled", type: "boolean?", description: "Whether element accepts input. Only present when false."),
        AttributeEntry(name: "focused", type: "boolean?", description: "Whether element has keyboard focus. Only present when true."),
        AttributeEntry(name: "actions", type: "array?", description: "Available actions for this element (e.g., ['press', 'show_menu'])."),
        AttributeEntry(name: "children", type: "array?", description: "Child elements. Controlled by --depth flag."),
    ]
}
