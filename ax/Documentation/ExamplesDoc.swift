//
//  ExamplesDoc.swift
//  ax
//
//  Documentation with practical workflow examples for AI agents.
//

import Foundation

/// Documentation for practical usage examples
struct ExamplesDoc {

    static let text = """
PRACTICAL EXAMPLES

These examples show common workflows for automating macOS applications.

────────────────────────────────────────────────────────────────────────────────
DISCOVERING UI ELEMENTS
────────────────────────────────────────────────────────────────────────────────

1. List running apps to find the target app's PID:
   ax ls
   → {"displays": [...], "apps": [{"pid": 1234, "name": "Safari", ...}, ...]}

2. List windows for that app:
   ax ls 1234
   → [{"id": "1234:567891234", "title": "GitHub", "frame": {...}}, ...]

3. Explore the UI element tree:
   ax ls 1234 --depth 5
   → Returns nested elements with roles, titles, values, and actions

4. Find element at specific screen coordinates:
   ax ls @500,300
   → Returns the element under that point

5. Look up a specific element by ID:
   ax ls 1234:567891234
   → Returns that element and its children

────────────────────────────────────────────────────────────────────────────────
CLICKING BUTTONS AND CONTROLS
────────────────────────────────────────────────────────────────────────────────

By element ID (preferred - most reliable):
   ax click 1234:567891234

By screen coordinates (when element ID unavailable):
   ax click @500,300

With offset from element (click 50px right and 30px down from element origin):
   ax click 1234:567891234@50,30

Right-click for context menus:
   ax rightclick 1234:567891234

────────────────────────────────────────────────────────────────────────────────
TYPING TEXT
────────────────────────────────────────────────────────────────────────────────

Type into the currently focused element:
   ax type "Hello, world!"

Focus an element first, then type:
   ax focus 1234:567891234
   ax type "Hello, world!"

Or use the combined form:
   ax type 1234:567891234 "Hello, world!"

────────────────────────────────────────────────────────────────────────────────
KEYBOARD SHORTCUTS
────────────────────────────────────────────────────────────────────────────────

Common shortcuts:
   ax key cmd+s                    # Save
   ax key cmd+c                    # Copy
   ax key cmd+v                    # Paste
   ax key cmd+z                    # Undo
   ax key cmd+shift+z              # Redo
   ax key cmd+a                    # Select all
   ax key cmd+w                    # Close window
   ax key cmd+q                    # Quit app
   ax key cmd+t                    # New tab
   ax key cmd+n                    # New window

Navigation:
   ax key tab                      # Next field
   ax key shift+tab                # Previous field
   ax key return                   # Confirm/submit
   ax key escape                   # Cancel/close

Arrow keys with repeat:
   ax key down --repeat 5          # Move down 5 times
   ax key right --repeat 10        # Move right 10 times

Function keys:
   ax key f1                       # F1 key
   ax key cmd+f5                   # VoiceOver toggle

────────────────────────────────────────────────────────────────────────────────
WORKING WITH TEXT FIELDS
────────────────────────────────────────────────────────────────────────────────

Clear and replace text in a field:
   ax focus 1234:567891234         # Focus the field
   ax key cmd+a                    # Select all
   ax type "new text"              # Type replaces selection

Get selected text:
   ax selection 1234:567891234
   → {"text": "selected words", "range": [10, 24]}

Set a field's value directly:
   ax set 1234:567891234 "new value"

────────────────────────────────────────────────────────────────────────────────
SCROLLING
────────────────────────────────────────────────────────────────────────────────

Scroll at coordinates:
   ax scroll @500,300 down 200     # Scroll down 200 pixels
   ax scroll @500,300 up 100       # Scroll up 100 pixels

Scroll within an element:
   ax scroll 1234:567891234 down 300

Directions: up, down, left, right

────────────────────────────────────────────────────────────────────────────────
WINDOW MANAGEMENT
────────────────────────────────────────────────────────────────────────────────

Move a window:
   ax move 1234:567891234 --to @100,100

Resize a window:
   ax resize 1234:567891234 800x600

Bring window to front:
   ax action 1234:567891234 raise

Close a window:
   ax action 1234:567891234 close

────────────────────────────────────────────────────────────────────────────────
DRAG AND DROP
────────────────────────────────────────────────────────────────────────────────

Drag between coordinates:
   ax drag @100,200 --to @300,400

Drag from element to element:
   ax drag 1234:111111@10,10 --to 1234:222222@10,10

Drag file to an app (drag from Finder to target):
   ax drag 5678:333333 --to 1234:444444

────────────────────────────────────────────────────────────────────────────────
SCREENSHOTS
────────────────────────────────────────────────────────────────────────────────

Screenshot all displays:
   ax ls --screenshot /tmp/screen.png

Screenshot as base64 (for embedding):
   ax ls --screenshot-base64

Screenshot specific window:
   ax ls 1234:567891234 --screenshot /tmp/window.png

Screenshot specific element:
   ax ls 1234:567891234 --screenshot /tmp/element.png

Exclude a window from screenshot (e.g., your own overlay):
   ax ls --screenshot /tmp/screen.png --exclude 1234:567891234

────────────────────────────────────────────────────────────────────────────────
APP LIFECYCLE
────────────────────────────────────────────────────────────────────────────────

Launch an app by bundle ID:
   ax launch com.apple.Safari
   ax launch com.apple.Notes
   ax launch com.apple.TextEdit
   → {"pid": 1234, "name": "Safari", "bundle_id": "com.apple.Safari"}

Quit an app by PID:
   ax quit 1234
   → {"quit": true, "pid": 1234}

Activate (bring to front) an app:
   ax focus 1234

────────────────────────────────────────────────────────────────────────────────
AUTOMATION SEQUENCES (LOCKING INPUT)
────────────────────────────────────────────────────────────────────────────────

Lock human input during automation (ax commands still work):
   ax lock --timeout 30            # Lock for max 30 seconds

   # ... run automation commands ...
   ax click 1234:567891234
   ax type "automated text"
   ax key cmd+s

   ax unlock                       # Unlock when done

Emergency unlock: Triple-press Escape key

────────────────────────────────────────────────────────────────────────────────
WORKFLOW: FILL OUT A FORM
────────────────────────────────────────────────────────────────────────────────

# 1. Find the app
ax ls | jq '.apps[] | select(.name == "Safari")'

# 2. Find form fields
ax ls 1234 --depth 10 | jq '.. | select(.role? == "text_field")'

# 3. Fill each field
ax click 1234:111111              # Click first field
ax type "John Doe"
ax key tab                        # Move to next field
ax type "john@example.com"
ax key tab
ax type "555-1234"

# 4. Submit the form
ax click 1234:222222              # Click submit button

────────────────────────────────────────────────────────────────────────────────
WORKFLOW: INTERACT WITH MENUS
────────────────────────────────────────────────────────────────────────────────

# Open application menu
ax click 1234:333333              # Click menu bar item
ax ls 1234 --depth 5              # Find menu items
ax click 1234:444444              # Click desired menu item

# Or use keyboard shortcuts when available
ax key cmd+shift+n                # Often faster than menu navigation

────────────────────────────────────────────────────────────────────────────────
WORKFLOW: NAVIGATE A LIST OR TABLE
────────────────────────────────────────────────────────────────────────────────

# Find rows in a table
ax ls 1234 --depth 10 | jq '.. | select(.role? == "row")'

# Click to select a row
ax click 1234:555555

# Or navigate with arrow keys
ax click 1234:666666              # Focus the table/list first
ax key down --repeat 3            # Move to 4th row
ax key return                     # Activate selected row

────────────────────────────────────────────────────────────────────────────────
TIPS FOR AI AGENTS
────────────────────────────────────────────────────────────────────────────────

1. Always start by discovering the UI structure with 'ax ls <pid> --depth N'

2. Element IDs are stable while the app runs - cache and reuse them

3. Use 'ax focused' to verify which element has focus before typing

4. After clicking, allow time for UI to update before next action

5. Check the "actions" array on elements to see what's available

6. Use coordinate clicks (@x,y) as fallback when elements aren't accessible

7. The "origin" field gives absolute screen coordinates for any element

8. Screenshots help verify UI state during automation

9. Use 'ax lock' for complex sequences to prevent human interference

10. Exit codes tell you if an action succeeded:
    0 = success, 1 = not found, 2 = permission denied, 3 = action failed
"""

    static let entries: [ExampleEntry] = [
        ExampleEntry(
            title: "Discover UI elements",
            steps: [
                "ax ls                          # List apps to find PID",
                "ax ls <pid>                    # List windows",
                "ax ls <pid> --depth 5          # Explore element tree",
                "ax ls @500,300                 # Find element at coordinates"
            ],
            description: "Start by exploring the app's UI structure to find element IDs"
        ),
        ExampleEntry(
            title: "Click a button",
            steps: [
                "ax ls <pid> --depth 5          # Find button's element ID",
                "ax click <pid>:<hash>          # Click by element ID"
            ],
            description: "Locate the button in the element tree, then click it by ID"
        ),
        ExampleEntry(
            title: "Type into a text field",
            steps: [
                "ax focus <pid>:<hash>          # Focus the text field",
                "ax key cmd+a                   # Select all existing text",
                "ax type \"new text\"             # Type new content"
            ],
            description: "Focus the field, optionally clear it, then type"
        ),
        ExampleEntry(
            title: "Fill out a form",
            steps: [
                "ax click <pid>:<field1>        # Click first field",
                "ax type \"value 1\"",
                "ax key tab                     # Move to next field",
                "ax type \"value 2\"",
                "ax click <pid>:<submit>        # Click submit button"
            ],
            description: "Navigate between fields with Tab, type values, then submit"
        ),
        ExampleEntry(
            title: "Take a screenshot",
            steps: [
                "ax ls --screenshot /tmp/screen.png              # Full screen",
                "ax ls <pid>:<window> --screenshot /tmp/win.png  # Window only"
            ],
            description: "Capture the screen or specific elements for verification"
        ),
        ExampleEntry(
            title: "Launch and control apps",
            steps: [
                "ax launch com.apple.Safari     # Launch by bundle ID",
                "ax focus <pid>                 # Bring to front",
                "ax quit <pid>                  # Quit when done"
            ],
            description: "Start apps, switch focus, and close when finished"
        ),
        ExampleEntry(
            title: "Safe automation sequence",
            steps: [
                "ax lock --timeout 30           # Lock human input",
                "ax click <pid>:<hash>          # Perform actions...",
                "ax type \"automated input\"",
                "ax key cmd+s",
                "ax unlock                      # Unlock when done"
            ],
            description: "Lock input to prevent interference during automation"
        ),
    ]
}

struct ExampleEntry: Encodable {
    let title: String
    let steps: [String]
    let description: String
}
