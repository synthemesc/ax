# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ax` is a macOS command-line tool that exposes the accessibility tree as JSON for AI agents. It allows listing applications, inspecting windows and UI elements, simulating clicks and keyboard input, and taking screenshots.

**Status:** Fully functional as of 2026-02-01. All commands implemented and tested.

## Quick Reference

```bash
# Build
xcodebuild build -scheme ax -configuration Debug

# Run (after build)
~/Library/Developer/Xcode/DerivedData/ax-*/Build/Products/Debug/ax

# Common commands
ax ls                        # List apps
ax ls <pid>                  # List windows
ax ls <pid> --depth 3        # Element tree
ax ls <pid>-<hash>           # Lookup element by ID
ax click <pid>-<hash>        # Click element
ax click --pos x,y           # Click coordinates
ax type "text"               # Type into focused element
ax key cmd+s                 # Key combo
ax launch com.apple.Safari   # Launch app
ax quit <pid>                # Quit app
```

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
# List running applications
ax ls

# List windows for an app (by PID)
ax ls 1234

# Show element tree with depth limit
ax ls 1234 --depth 3

# Take screenshot
ax ls --screenshot /tmp/screen.png
ax ls 1234 --screenshot-base64

# Click at position or element
ax click --pos 100,200
ax click 0x7f8a2c

# Type text
ax type "Hello, world!"

# Key combinations
ax key cmd+s
ax key down --repeat 5

# Scroll
ax scroll up 100
ax scroll --pos 500,500 down 200

# Perform accessibility action
ax action 0x7f8a2c press

# Focus app or element
ax focus 1234

# Launch/quit applications
ax launch com.apple.Safari
ax quit 1234
```

## Architecture

```
ax/
├── main.swift              # Entry point, command dispatch, help text
├── Core/
│   ├── ExitCode.swift      # Exit codes (0=success, 1=not found, 2=permission, 3=action failed)
│   └── AXError.swift       # Error types mapped to exit codes
├── Accessibility/
│   ├── Element.swift       # AXUIElement wrapper with attribute accessors
│   ├── ElementID.swift     # Hex pointer ID handling + registry
│   └── ElementTree.swift   # Recursive tree traversal
├── Models/
│   ├── AppInfo.swift       # Codable: pid, name, bundleId
│   ├── WindowInfo.swift    # Codable: id, title, bounds
│   └── ElementInfo.swift   # Codable: id, role, title, value, actions, children
├── CLI/
│   ├── CommandParser.swift # Manual argv parsing
│   └── Output.swift        # JSON to stdout, errors to stderr
├── Commands/
│   ├── ListCommand.swift   # ax ls
│   ├── ClickCommand.swift  # ax click, ax rightclick
│   ├── TypeCommand.swift   # ax type
│   ├── KeyCommand.swift    # ax key
│   ├── ScrollCommand.swift # ax scroll
│   ├── ActionCommand.swift # ax action
│   ├── FocusCommand.swift  # ax focus
│   ├── LaunchCommand.swift # ax launch
│   └── QuitCommand.swift   # ax quit
├── Input/
│   ├── MouseEvents.swift   # CGEvent mouse clicks
│   ├── KeyboardEvents.swift# CGEvent keyboard
│   └── KeyCodes.swift      # String to keycode mapping
└── Screenshot/
    └── ScreenCapture.swift # ScreenCaptureKit wrapper
```

## Key Implementation Details

- **Frameworks:** ApplicationServices (AXUIElement), CoreGraphics (CGEvent), AppKit (NSWorkspace), ScreenCaptureKit, Carbon.HIToolbox (key codes)
- **Permissions:** Requires Accessibility permission (`AXIsProcessTrusted()`) and Screen Recording for screenshots
- **Element IDs:** Stable `pid-hash` format (e.g., `619-1668249066`) using CFHash - persists across invocations
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

Element IDs use the format `<pid>-<hash>` (e.g., `619-1668249066`):
- **PID:** Identifies which application to search
- **Hash:** CFHash of the AXUIElement, stable for the same underlying UI element

**Key insight:** While AXUIElement pointers change on each API call (different wrapper objects), `CFHash()` returns the same value for elements referring to the same underlying NSView/NSWindow. This enables:

```bash
# First invocation - get element IDs
ax ls 619 --depth 3
# Output includes: "id": "619-1668249066"

# Second invocation - use that ID
ax click 619-1668249066   # Works!
ax ls 619-1668249066      # Works!
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

### Accessibility Action Names

Actions have AX prefix internally but user-friendly names in CLI:
- User input: `press`, `showMenu`, `increment`
- Internal: `AXPress`, `AXShowMenu`, `AXIncrement`
- Conversion in `ActionCommand.formatActionName()` and `ElementTree.formatActionName()`

### Common AX Attributes Used

```swift
kAXRoleAttribute          // "AXButton", "AXTextField", etc.
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

### File Summary (24 Swift files)

| File | Purpose |
|------|---------|
| `main.swift` | Entry point, help text, command dispatch |
| `Core/ExitCode.swift` | Exit code enum (0-4) |
| `Core/AXError.swift` | Error types with exit code mapping |
| `Accessibility/Element.swift` | AXUIElement wrapper, attribute access |
| `Accessibility/ElementID.swift` | **Stable IDs via CFHash**, tree search lookup |
| `Accessibility/ElementTree.swift` | Recursive tree traversal for JSON output |
| `Models/AppInfo.swift` | App JSON model (pid, name, bundleId) |
| `Models/WindowInfo.swift` | Window JSON model + FrameInfo |
| `Models/ElementInfo.swift` | Element JSON model (recursive) |
| `CLI/Output.swift` | JSON output, stderr errors |
| `CLI/CommandParser.swift` | Manual argv parsing |
| `Commands/ListCommand.swift` | `ax ls` - apps, windows, elements |
| `Commands/ClickCommand.swift` | `ax click` / `ax rightclick` |
| `Commands/TypeCommand.swift` | `ax type` - Unicode text input |
| `Commands/KeyCommand.swift` | `ax key` - key combos |
| `Commands/ScrollCommand.swift` | `ax scroll` |
| `Commands/ActionCommand.swift` | `ax action` - AX actions |
| `Commands/FocusCommand.swift` | `ax focus` - activate app/element |
| `Commands/LaunchCommand.swift` | `ax launch` - by bundle ID |
| `Commands/QuitCommand.swift` | `ax quit` - terminate app |
| `Input/MouseEvents.swift` | CGEvent mouse simulation |
| `Input/KeyboardEvents.swift` | CGEvent keyboard simulation |
| `Input/KeyCodes.swift` | Key name → virtual key code mapping |
| `Screenshot/ScreenCapture.swift` | ScreenCaptureKit wrapper |

### Future Enhancements

Potential improvements not yet implemented:
1. **Element lookup by path** - e.g., `ax ls 1234 "AXWindow/AXButton[@title='OK']"`
2. **Watch mode** - Monitor element changes
3. **Attribute setting** - `ax set <id> value "text"`
4. **Element search** - Find by role/title across tree
