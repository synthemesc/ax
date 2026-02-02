# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ax` is a macOS command-line tool that exposes the accessibility tree as JSON for AI agents. It allows listing applications, inspecting windows and UI elements, simulating clicks and keyboard input, and taking screenshots.

**Status:** Fully functional as of 2026-02-01. All commands implemented and tested.

## Quick Reference

```bash
# Build
xcodebuild build -scheme ax -configuration Debug
xcodebuild build -scheme axlockd -configuration Debug
xcodebuild build -scheme axtest -configuration Debug

# Run (after build)
~/Library/Developer/Xcode/DerivedData/ax-*/Build/Products/Debug/ax

# Run tests
./tests/test_ax.sh

# Common commands
ax ls                        # List displays + apps
ax ls <pid>                  # List windows (includes display ID)
ax ls <pid> --depth 3        # Element tree
ax ls <pid>:<hash>           # Lookup element by ID
ax ls @500,300               # Element at screen coordinates
ax click <pid>:<hash>        # Click element
ax click @100,200            # Click at absolute coordinates
ax click <pid>:<hash>@50,50  # Click at offset from element
ax type "text"               # Type into focused element
ax key cmd+s                 # Key combo
ax cursor                    # Get mouse position
ax focused                   # Get focused element
ax selection <id>            # Get selected text
ax set <id> "new value"      # Set element value
ax move <id> --to @100,100   # Move window
ax resize <id> 800x600       # Resize window
ax drag @100,200 --to @300,400  # Drag operation
ax launch com.apple.Safari   # Launch app
ax quit <pid>                # Quit app
ax lock                      # Lock human input
ax lock --timeout 30         # Lock with timeout
ax unlock                    # Unlock input
```

## Address Formats

Universal addressing system for targeting points, rects, and elements:

| Format | Example | Meaning |
|--------|---------|---------|
| `@x,y` | `@500,300` | Absolute screen point |
| `@x,y+WxH` | `@100,200+400x300` | Absolute screen rect |
| `pid` | `1234` | Application by PID |
| `pid:hash` | `1234:5678901` | Element by ID |
| `pid:hash+WxH` | `1234:5678901+400x300` | Rect from element origin |
| `pid:hash@dx,dy` | `1234:5678901@50,50` | Point offset from element |
| `pid:hash@dx,dy+WxH` | `1234:5678901@50,50+400x300` | Rect offset from element |

Operators:
- `@` prefix = absolute screen coordinates (or offset when after element)
- `:` = separates PID from element hash
- `+WxH` = extends a point into a rect with specified size

## Build Commands

```bash
# Build (Debug)
xcodebuild build -scheme ax -configuration Debug

# Build (Release)
xcodebuild build -scheme ax -configuration Release

# Clean
xcodebuild clean -scheme ax
```

The built executable is located in the derived data directory:
```bash
~/Library/Developer/Xcode/DerivedData/ax-*/Build/Products/Debug/ax
```

## Usage

```bash
# List displays and running applications
ax ls
# → {"displays": [...], "apps": [{"pid": 1234, "name": "Safari", "bundle_id": "com.apple.Safari"}, ...]}

# List windows for an app (by PID) - includes which display each window is on
ax ls 1234
# → [{"id": "1234:567891234", "title": "GitHub", "frame": {...}, "display": 1}, ...]

# Show element tree with depth limit (includes "origin" for absolute position)
ax ls 1234 --depth 3

# Show element at screen coordinates
ax ls @500,300

# Show elements within a screen rect
ax ls @100,200+400x300

# Take screenshot
ax ls --screenshot /tmp/screen.png
ax ls 1234 --screenshot-base64

# Click at absolute coordinates or element
ax click @100,200
ax click 1234:5678901

# Click at offset from element (50px right, 50px down from element's top-left)
ax click 1234:5678901@50,50

# Type text
ax type "Hello, world!"

# Key combinations
ax key cmd+s
ax key down --repeat 5

# Scroll
ax scroll @500,300 down 100
ax scroll 1234:5678901 up 200

# Perform accessibility action
ax action 1234:5678901 press

# Focus app or element
ax focus 1234

# Get current mouse position
ax cursor
# → {"x": 500, "y": 300}

# Get focused element
ax focused

# Get selected text from a text element
ax selection 1234:5678901
# → {"text": "selected words", "range": [10, 14]}

# Set element value
ax set 1234:5678901 "new text"

# Move window to position
ax move 1234:5678901 --to @100,100

# Resize window
ax resize 1234:5678901 800x600

# Drag from one position to another
ax drag @100,200 --to @300,400
ax drag 1234:5678901@10,10 --to 1234:9876543@10,10

# Launch/quit applications
ax launch com.apple.Safari
ax quit 1234

# Lock/unlock input (for automation sequences)
ax lock                      # Lock human HID input, ax commands still work
ax lock --timeout 30         # Lock with 30 second timeout (max 300)
ax unlock                    # Unlock human input
# Triple-press Escape to emergency unlock
# Lock shows overlay on all screens
```

## Architecture

```
ax/
├── main.swift              # Entry point, command dispatch, help text
├── Core/
│   ├── ExitCode.swift      # Exit codes (0=success, 1=not found, 2=permission, 3=action failed)
│   ├── AXError.swift       # Error types mapped to exit codes
│   └── AXNameFormatter.swift # AX name ↔ snake_case conversion
├── Accessibility/
│   ├── Element.swift       # AXUIElement wrapper with attribute accessors
│   ├── ElementID.swift     # Hex pointer ID handling + registry
│   └── ElementTree.swift   # Recursive tree traversal
├── Models/
│   ├── AppInfo.swift       # Codable: pid, name, bundleId
│   ├── DisplayInfo.swift   # Codable: id, bounds, scale, main + AppListResult
│   ├── WindowInfo.swift    # Codable: id, title, frame, display
│   └── ElementInfo.swift   # Codable: id, role, title, value, actions, children
├── CLI/
│   ├── CommandParser.swift # Manual argv parsing
│   ├── Address.swift       # Universal address parser (@x,y, pid:hash, etc.)
│   ├── AddressResolver.swift # Resolves addresses to points/elements
│   └── Output.swift        # JSON to stdout, errors to stderr
├── Commands/
│   ├── ListCommand.swift   # ax ls
│   ├── ClickCommand.swift  # ax click, ax rightclick
│   ├── TypeCommand.swift   # ax type
│   ├── KeyCommand.swift    # ax key
│   ├── ScrollCommand.swift # ax scroll
│   ├── ActionCommand.swift # ax action
│   ├── FocusCommand.swift  # ax focus
│   ├── CursorCommand.swift # ax cursor
│   ├── FocusedCommand.swift # ax focused
│   ├── SelectionCommand.swift # ax selection
│   ├── SetCommand.swift    # ax set
│   ├── MoveCommand.swift   # ax move
│   ├── ResizeCommand.swift # ax resize
│   ├── DragCommand.swift   # ax drag
│   ├── LaunchCommand.swift # ax launch
│   ├── QuitCommand.swift   # ax quit
│   ├── LockCommand.swift   # ax lock
│   └── UnlockCommand.swift # ax unlock
├── Lock/
│   └── LockState.swift     # PID file management for lock state
├── Input/
│   ├── MouseEvents.swift   # CGEvent mouse clicks
│   ├── KeyboardEvents.swift# CGEvent keyboard
│   └── KeyCodes.swift      # String to keycode mapping
├── Screenshot/
│   └── ScreenCapture.swift # ScreenCaptureKit wrapper
└── Documentation/
    ├── HelpCommand.swift   # ax help subcommand dispatcher
    ├── RolesDoc.swift      # Role reference documentation
    ├── ActionsDoc.swift    # Action reference documentation
    ├── AttributesDoc.swift # Attribute reference documentation
    └── KeysDoc.swift       # Key names reference documentation

axlockd/                        # Separate daemon app for input locking
├── axlockdApp.swift            # Daemon entry point, coordinates tap + overlay + timeout
├── EventTap.swift              # CGEventTap wrapper, escape detection
├── OverlayWindow.swift         # NSWindow subclass for visual feedback
└── axlockd.entitlements        # Entitlements (no sandbox for event tap)
```

## Key Implementation Details

- **Frameworks:** ApplicationServices (AXUIElement), CoreGraphics (CGEvent), AppKit (NSWorkspace), ScreenCaptureKit, Carbon.HIToolbox (key codes)
- **Permissions:** Requires Accessibility permission (`AXIsProcessTrusted()`) and Screen Recording for screenshots
- **Element IDs:** Stable `pid:hash` format (e.g., `619:1668249066`) using CFHash - persists across invocations
- **Universal Addressing:** Supports absolute coords (`@x,y`), element IDs (`pid:hash`), offsets (`pid:hash@dx,dy`), and rects (`+WxH`)
- **Origin Field:** Elements include `origin` with absolute screen position for easy targeting
- **JSON Output:** All commands output JSON to stdout, errors go to stderr

## Exit Codes

- `0` - Success
- `1` - Element or application not found
- `2` - Permission denied (accessibility or screen recording)
- `3` - Action failed
- `4` - Invalid arguments

## Build Configuration

- **Target:** macOS 26.2+, Swift 5.0
- **Dependencies:** No external packages (Foundation, AppKit, CoreGraphics, ScreenCaptureKit only)
- Hardened runtime enabled
- Strict compiler warnings enabled

## Implementation Notes

### Element IDs - Stable Across Invocations

Element IDs use the format `<pid>:<hash>` (e.g., `619:1668249066`):
- **PID:** Identifies which application to search
- **Hash:** CFHash of the AXUIElement, stable for the same underlying UI element

**Key insight:** While AXUIElement pointers change on each API call (different wrapper objects), `CFHash()` returns the same value for elements referring to the same underlying NSView/NSWindow. This enables:

```bash
# First invocation - get element IDs
ax ls 619 --depth 3
# Output includes: "id": "619:1668249066"

# Second invocation - use that ID
ax click 619:1668249066   # Works!
ax ls 619:1668249066      # Works!
```

**Lookup mechanism:** When given an ID, the system:
1. Parses PID and hash from the ID
2. Creates `AXUIElementCreateApplication(pid)`
3. Walks the element tree comparing `CFHash()` until match found
4. Caches found elements for repeated lookups

**Limitation:** IDs are only stable while the app is running. If an app restarts, it gets a new PID and new element hashes.

**Critical Discovery (2026-02-01):** The key insight was that `CFHash(axElement)` returns a stable hash based on the *underlying* UI element (NSView/NSWindow), not the AXUIElement wrapper object. Two different AXUIElement pointers referencing the same button will have identical CFHash values. This was verified experimentally:
```
// Same element queried twice = different pointers, same hash
app1 pointer: 0x0000000c980dc030
app2 pointer: 0x0000000c980dc150  ← Different!
app1 hash: 1634759307
app2 hash: 1634759307              ← Same!
CFEqual(app1, app2): true
```

### AXUIElement Wrapper Pattern (Element.swift)

The `Element` class follows patterns from [AXSwift](https://github.com/tmandry/AXSwift):

```swift
// Safe attribute access - returns nil for missing/unsupported, throws for real errors
func attribute<T>(_ name: String) throws -> T?

// Batch fetching for performance (single IPC call)
func attributes(_ names: [String]) throws -> [String: Any]
```

**Key behaviors:**
- `.noValue` and `.attributeUnsupported` return `nil` (not errors)
- AXValue types (CGPoint, CGSize, CGRect, CFRange) are automatically unpacked
- No manual CFRetain/CFRelease needed - system handles at API boundaries

### Error Handling Strategy

All errors flow through `AXError` enum which maps to exit codes:

| Error Type | Exit Code | When Used |
|------------|-----------|-----------|
| `.notFound` | 1 | Element/app doesn't exist, invalid element |
| `.permissionDenied` | 2 | Accessibility or screen recording denied |
| `.actionFailed` | 3 | Action couldn't complete, API errors |
| `.invalidArguments` | 4 | Bad CLI arguments |

`Output.error()` prints to stderr and calls `exit()` - it's a `Never` returning function.

### Screenshot Implementation

Uses ScreenCaptureKit (not deprecated CGWindowListCreateImage). Key points:
- `SCShareableContent.excludingDesktopWindows()` to get available content
- `SCContentFilter` to select display/windows
- `SCScreenshotManager.captureImage()` for actual capture
- Async APIs wrapped with semaphore for synchronous CLI use

Permission check: `CGPreflightScreenCaptureAccess()` / `CGRequestScreenCaptureAccess()`

### Keyboard Input

Two methods in `KeyboardEvents.swift`:

1. **Unicode typing** (`type()`) - Uses `CGEventKeyboardSetUnicodeString` for arbitrary text
2. **Key combos** (`pressKey()`) - Uses virtual key codes from `KeyCodes.swift`

Key combo parsing: `"cmd+shift+s"` → modifiers (`.maskCommand`, `.maskShift`) + key code (kVK_ANSI_S)

### Mouse Events

`MouseEvents.swift` uses CGEvent for clicks:
- Events posted to `.cghidEventTap` for system-wide effect
- Double-click sets `.mouseEventClickState` to 2
- Drag is: mouseDown → mouseDragged → mouseUp

### Command Parser

Manual argv parsing in `CommandParser.swift` (no ArgumentParser dependency):
- Returns `Command` enum with associated args structs
- Positional args vs flags (`--depth`, `--pos`, etc.)
- Position format: `x,y` (comma-separated integers)

### Async/Sync Bridge

ScreenCaptureKit is async, but CLI is sync. Pattern used:

```swift
private static func runAsync(_ block: @escaping () async throws -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do { try await block() }
        catch { Output.error(...) }
        semaphore.signal()
    }
    semaphore.wait()
}
```

### JSON Output

All commands output Codable structs via `Output.json()`:
- Pretty-printed with sorted keys by default
- Nested structs for complex results (e.g., `ClickResult`, `LaunchResult`)
- snake_case for JSON keys where needed (via `CodingKeys`)

### Name Formatting (AXNameFormatter)

All accessibility names (roles, subroles, actions) are converted to snake_case for output:
- **Internal (AX API):** `AXStaticText`, `AXShowMenu`, `AXCloseButton`
- **Output (JSON):** `static_text`, `show_menu`, `close_button`
- **Input (CLI):** `ax action <id> show_menu` → converted to `AXShowMenu` internally

Conversion handled by `AXNameFormatter.swift`:
- `formatForDisplay()`: `AXStaticText` → `static_text`
- `formatForAPI()`: `show_menu` → `AXShowMenu`

### Help System

Documentation subcommands for AI agents:
```bash
ax help roles        # List accessibility roles
ax help actions      # List accessibility actions
ax help attributes   # Explain output fields
ax help keys         # List key names for ax key
ax help --json       # Machine-readable documentation (JSON)
```

### Click Command Output

The click command returns a unified JSON format with a `method` field:
```json
{"id": "619-123456", "method": "press", "x": 100, "y": 200}  // Used AXPress action
{"id": "619-123456", "method": "mouse", "x": 100, "y": 200}  // Used coordinate click
{"method": "mouse", "x": 100, "y": 200}                       // Position-only click
```

### Element Screenshots

Screenshots can be taken of specific elements (cropped to element bounds):
```bash
ax ls <element-id> --screenshot /tmp/element.png
ax ls <element-id> --screenshot-base64
```

### Display Information

The `ax ls` command returns display info alongside apps, giving AI agents the coordinate space:
```json
{
  "displays": [
    {"id": 1, "x": 0, "y": 0, "width": 2560, "height": 1600, "scale": 2, "main": true},
    {"id": 2, "x": 2560, "y": 0, "width": 1920, "height": 1080, "scale": 1}
  ],
  "apps": [...]
}
```

Each window in `ax ls <pid>` includes which display it's on:
```json
[
  {"id": "1234:567891234", "title": "GitHub", "frame": {...}, "display": 1},
  {"id": "1234:987654321", "title": "Google", "frame": {...}, "display": 2}
]
```

Display detection uses `NSScreen.screens` and determines which display a window is on by:
1. Checking if the window's origin falls within a display's bounds
2. Fallback: finding the display with the largest overlap area

### Common AX Attributes Used

```swift
kAXRoleAttribute          // "AXButton", "AXTextField", etc. (output as "button", "text_field")
kAXTitleAttribute         // Window/element title
kAXValueAttribute         // Current value (text fields, sliders)
kAXPositionAttribute      // CGPoint (requires AXValue unpacking)
kAXSizeAttribute          // CGSize (requires AXValue unpacking)
kAXChildrenAttribute      // Array of child elements
kAXWindowsAttribute       // App's windows
kAXFocusedAttribute       // Bool - is focused
kAXEnabledAttribute       // Bool - is enabled
kAXIdentifierAttribute    // Developer-set identifier
```

### Troubleshooting

**"Accessibility permission denied"**
- Grant access: System Settings > Privacy & Security > Accessibility
- Add Terminal (or the app running `ax`) to the list

**"Screen capture permission denied"**
- Grant access: System Settings > Privacy & Security > Screen Recording
- Required for `--screenshot` and `--screenshot-base64`

**"Element not found" after app restart**
- Element IDs include PID, which changes on restart
- Re-run `ax ls <pid>` to get new IDs

**"cannotComplete" error on action**
- Some elements don't support certain actions
- Check available actions with `ax ls <id>` (look at "actions" array)
- Try coordinate-based click instead: `ax click --pos x,y`

**Stale element reference**
- UI changed since ID was obtained
- Element may have been removed/recreated
- Re-traverse tree to get fresh IDs

### File Summary (46 Swift files)

| File | Purpose |
|------|---------|
| `main.swift` | Entry point, help text, command dispatch |
| `Core/ExitCode.swift` | Exit code enum (0-4) |
| `Core/AXError.swift` | Error types with exit code mapping |
| `Core/AXNameFormatter.swift` | AX name ↔ snake_case conversion |
| `Accessibility/Element.swift` | AXUIElement wrapper, attribute access |
| `Accessibility/ElementID.swift` | **Stable IDs via CFHash**, tree search lookup |
| `Accessibility/ElementTree.swift` | Recursive tree traversal for JSON output |
| `Models/AppInfo.swift` | App JSON model (pid, name, bundleId) |
| `Models/DisplayInfo.swift` | Display JSON model + AppListResult wrapper |
| `Models/WindowInfo.swift` | Window JSON model + FrameInfo + display ID |
| `Models/ElementInfo.swift` | Element JSON model (recursive) + PointInfo |
| `CLI/Output.swift` | JSON output, stderr errors |
| `CLI/CommandParser.swift` | Manual argv parsing with Address support |
| `CLI/Address.swift` | Universal address types and parser |
| `CLI/AddressResolver.swift` | Resolve addresses to points/rects/elements |
| `Commands/ListCommand.swift` | `ax ls` - apps, windows, elements, point/rect queries |
| `Commands/ClickCommand.swift` | `ax click` / `ax rightclick` |
| `Commands/TypeCommand.swift` | `ax type` - Unicode text input |
| `Commands/KeyCommand.swift` | `ax key` - key combos |
| `Commands/ScrollCommand.swift` | `ax scroll` |
| `Commands/ActionCommand.swift` | `ax action` - AX actions |
| `Commands/FocusCommand.swift` | `ax focus` - activate app/element |
| `Commands/CursorCommand.swift` | `ax cursor` - get mouse position |
| `Commands/FocusedCommand.swift` | `ax focused` - get focused element |
| `Commands/SelectionCommand.swift` | `ax selection` - get selected text |
| `Commands/SetCommand.swift` | `ax set` - set element value |
| `Commands/MoveCommand.swift` | `ax move` - move window/element |
| `Commands/ResizeCommand.swift` | `ax resize` - resize window/element |
| `Commands/DragCommand.swift` | `ax drag` - drag operation |
| `Commands/LaunchCommand.swift` | `ax launch` - by bundle ID |
| `Commands/QuitCommand.swift` | `ax quit` - terminate app |
| `Commands/LockCommand.swift` | `ax lock` - spawn axlockd daemon |
| `Commands/UnlockCommand.swift` | `ax unlock` - terminate axlockd daemon |
| `Lock/LockState.swift` | PID file management for lock state |
| `Input/MouseEvents.swift` | CGEvent mouse simulation + drag |
| `Input/KeyboardEvents.swift` | CGEvent keyboard simulation |
| `Input/KeyCodes.swift` | Key name → virtual key code mapping |
| `Screenshot/ScreenCapture.swift` | ScreenCaptureKit wrapper + rect capture |
| `Documentation/HelpCommand.swift` | `ax help` subcommand dispatcher |
| `Documentation/RolesDoc.swift` | Role reference documentation |
| `Documentation/ActionsDoc.swift` | Action reference documentation |
| `Documentation/AttributesDoc.swift` | Attribute reference documentation |
| `Documentation/KeysDoc.swift` | Key names reference documentation |
| `axlockd/axlockdApp.swift` | Lock daemon entry point + coordination |
| `axlockd/EventTap.swift` | CGEventTap wrapper, escape detection |
| `axlockd/OverlayWindow.swift` | Semi-transparent overlay windows |

### Universal Addressing Implementation

The address system is implemented in two files:

1. **`Address.swift`** - Defines the `Address` enum and `AddressParser`:
   - Parsing order matters: check for `@` prefix first (absolute), then `:` (element ID), then bare integer (PID)
   - `+WxH` suffix always means "extend to rect" (uses `x` between width/height to avoid ambiguity with offsets)
   - `@` after an element ID means offset, not absolute

2. **`AddressResolver.swift`** - Resolves addresses to concrete values:
   - `resolvePoint()` - Returns `ResolvedPoint` with x, y, and optional source element
   - `resolveRect()` - Returns `ResolvedRect` with x, y, width, height
   - `resolveElement()` - Returns the `Element`, using `AXUIElementCopyElementAtPosition` for coordinate-based lookups
   - `elementsInRect()` - Finds all elements intersecting a rect (walks all apps)

**Design decision:** The `@` operator is overloaded - `@500,300` is absolute (no element before it), but `1234:5678@50,50` is relative (element before it). This is unambiguous because element IDs always contain `:`.

### Origin vs Frame

- `origin` contains x, y in **absolute screen coordinates** - use this for clicking/targeting
- `frame` contains x, y, width, height **relative to the parent element** - use this for understanding layout hierarchy
- For root elements (windows), frame uses absolute coordinates since there's no parent
- Screen coordinates use top-left origin (standard macOS accessibility coordinate system)

### Command Pattern

All commands follow the same pattern:
```swift
struct FooCommand {
    static func run(args: CommandParser.FooArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)
            // ... do work ...
            Output.json(result)
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
```

### Input Locking (ax lock/unlock)

The lock system allows automation sequences to run without human interference:

**Architecture:**
- `ax lock` spawns `axlockd` daemon (separate macOS app target)
- `axlockd` creates a CGEventTap to intercept HID input
- Events marked with `userData = 0x4158304158` pass through (ax-generated)
- Unmarked events (human input) are suppressed
- Visual overlay shows lock state on all screens

**Event Marking:**
- `MouseEvents` and `KeyboardEvents` use `CGEventSource.userData` to mark events
- The event tap checks this field to distinguish ax vs human input

**Safety Features:**
- Triple-press Escape to emergency unlock (tracked via timestamps)
- Timeout auto-unlocks (default 60s, max 300s)
- PID file at `~/.ax-lock.pid` tracks daemon process
- Stale PIDs detected and cleaned up automatically

**Output Format:**
```json
// ax lock
{"status": "locked", "pid": 12345, "window_id": 8765, "timeout": 60}
// ax unlock
{"status": "unlocked"}
// ax unlock when not locked
{"status": "not_locked"}
// ax lock when already locked
{"error": "already locked", "pid": 12345}
```

**Build Requirements:**
- Must build both `ax` and `axlockd` targets: `xcodebuild build -scheme axlockd -configuration Debug`
- `axlockd` is a macOS app bundle at `Products/Debug/axlockd.app/Contents/MacOS/axlockd`
- App Sandbox must be disabled for `axlockd` (requires accessibility permission for CGEventTap)

**IPC Mechanism:**
- `ax lock` creates temp file at `/tmp/ax-lock-<pid>.ipc`
- Passes `--ipc-file <path>` to axlockd
- axlockd writes window ID to file, parent reads after 500ms delay
- Temp file is cleaned up after reading
- Note: Using stdout pipe caused daemon to exit prematurely due to SIGPIPE when pipe closed

**Debugging:**
```bash
# Run axlockd directly to see errors
~/Library/Developer/Xcode/DerivedData/ax-*/Build/Products/Debug/axlockd.app/Contents/MacOS/axlockd --timeout 10

# Check if daemon is running
pgrep -l axlockd

# Check PID file
cat ~/.ax-lock.pid

# Force cleanup if stuck
rm ~/.ax-lock.pid && pkill axlockd
```

**Gotchas:**
- CGEventTap requires Accessibility permission for axlockd.app (System Settings > Privacy > Accessibility)
- If event tap fails to create, daemon exits immediately with error to stderr
- Overlay windows use `level = .statusBar + 1` and `ignoresMouseEvents = true`
- Event marker value `0x4158304158` = "AX0AX" in ASCII (must match in MouseEvents, KeyboardEvents, and EventTap)

### Backward Compatibility

- `--pos x,y` still works for click/scroll (converted to `@x,y` internally in CommandParser)
- Old element ID format with `-` separator was changed to `:` - this is a breaking change

### Screen Coordinate Systems

- **Accessibility API (kAXPositionAttribute):** Top-left origin, matches what we output
- **NSEvent.mouseLocation:** Bottom-left origin (Cocoa), converted in `CursorCommand`
- **CGEvent:** Top-left origin, no conversion needed

### Element Lookup at Point

`AddressResolver.elementAtPoint()` uses:
1. Get frontmost app via `NSWorkspace.shared.frontmostApplication`
2. Call `AXUIElementCopyElementAtPosition(app, x, y, &element)`
3. Fallback to system-wide element if app query fails

This means `ax ls @x,y` returns the element in the frontmost app at that point, not necessarily the topmost visible element if windows overlap.

## Testing

### Running Tests

```bash
# Build both targets first
xcodebuild build -scheme ax -configuration Debug
xcodebuild build -scheme axtest -configuration Debug

# Run the test suite
./tests/test_ax.sh
```

### Test Architecture

The test infrastructure consists of:

1. **`axtest/`** - A SwiftUI test harness app with UI elements for each test scenario
2. **`tests/test_ax.sh`** - Shell script test runner (26 tests)

**Key insight:** Tests use accessibility identifiers to find elements, and an `action_log` element to verify actions occurred. After clicking a button, the test reads the action_log's value to confirm the click registered.

### Test Coverage

| Category | Tests |
|----------|-------|
| Listing | `ls_apps`, `ls_windows`, `ls_depth`, `ls_element`, `ls_point` |
| Clicking | `click_element`, `click_coordinates`, `click_offset`, `rightclick` |
| Actions | `action_press` |
| Input | `type`, `key` |
| Scrolling | `scroll` |
| Focus | `focus`, `focused` |
| Queries | `cursor`, `selection` |
| Modification | `set`, `move`, `resize`, `drag` |
| App Control | `launch`, `quit` |
| Screenshots | `screenshot`, `screenshot_element` |
| Tree | `nested_tree` |

### Known Limitations

1. **`type` and `key` tests verify command execution only** - CGEvent keyboard input goes to the system's frontmost app (Terminal when running from script), not the target app. The tests verify the commands return valid JSON but can't verify text actually appeared.

2. **`focused` test accepts "no focused element"** - When running from Terminal, there may be no focused element in the accessibility sense.

3. **SwiftUI accessibility quirks:**
   - Empty `Text("")` elements may not appear in the accessibility tree
   - The `action_log` uses a disabled `TextField` instead of `Text` to ensure it's always present
   - `VStack`/`HStack` don't automatically become accessibility containers

### Test Harness Elements (axtest)

| Identifier | Element | Purpose |
|------------|---------|---------|
| `action_log` | TextField (disabled) | Verification target - shows last action |
| `test_button` | Button | Click/action tests |
| `test_button_2` | Button | Coordinate click tests |
| `test_toggle` | Toggle | Value change tests |
| `test_textfield` | TextField | Type/set/focus/selection tests |
| `test_textarea` | TextEditor | Multi-line text tests |
| `test_slider` | Slider | Numeric value tests |
| `test_stepper` | Stepper | Increment/decrement tests |
| `test_scrollview` | ScrollView | Scroll tests |
| `test_container` | GroupBox | Container for nested items |
| `nested_item_a/b/c/d` | Buttons | Tree traversal tests |
| `reset_button` | Button | Resets app state between tests |

### Writing New Tests

```bash
# Pattern for a new test
test_example() {
    reset_app  # Reset state

    local element_id
    element_id=$(find_element "identifier")  # Find by accessibility identifier

    if [[ -z "$element_id" ]]; then
        log_fail "example" "Could not find element"
        return
    fi

    "$AX_BIN" some_command "$element_id" >/dev/null 2>&1
    settle  # Wait for UI

    local result
    result=$(read_action_log)  # Or read element value directly

    if [[ "$result" == "expected" ]]; then
        log_pass "example"
    else
        log_fail "example" "Expected 'expected', got '$result'"
    fi
}
```

### Debugging Test Failures

```bash
# Get element tree
ax ls $(pgrep -x axtest) --depth 15 | jq '.[] | recurse | select(.identifier)'

# Check specific element
ax ls <element-id> | jq '{role, value, identifier, focused}'

# Verify action_log is present and readable
ax ls $(pgrep -x axtest) --depth 15 | jq 'recurse | select(.identifier == "action_log")'
```

### Gotchas

1. **`set -e` and arithmetic** - `((count++))` returns exit code 1 when count is 0. Use `((count++)) || true`.

2. **jq with large JSON** - Piping large JSON through subshells can fail silently. The test script saves the element tree to a temp file for reliable parsing.

3. **Element cache** - Tests cache the element tree for performance. If UI changes significantly during tests, call `refresh_cache`.

4. **Timing** - Use `settle` (0.2s sleep) after actions to let UI update. Increase if tests are flaky.

5. **Permissions** - Tests require Accessibility and Screen Recording permissions for Terminal.

### Future Enhancements

Potential improvements not yet implemented:
1. **Element lookup by path** - e.g., `ax ls 1234 "AXWindow/AXButton[@title='OK']"`
2. **Watch mode** - Monitor element changes
3. **Element search** - Find by role/title across tree
4. **Multi-app element at point** - Check all apps, not just frontmost
