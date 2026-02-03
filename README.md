# ax

A macOS command-line tool that exposes the accessibility tree as JSON for AI agents.

## Features

- List applications, windows, and UI element trees
- Click, type, and send keyboard shortcuts
- Take screenshots of displays, windows, or specific elements
- Query element properties, focused elements, and selected text
- Move, resize, and drag windows
- Launch and quit applications
- Lock human input during automation sequences

## Installation

### Homebrew

```bash
brew tap synthemesc/ax
brew install ax
```

### Build from Source

```bash
git clone https://github.com/synthemesc/ax.git
cd ax
xcodebuild build -scheme ax -configuration Release
xcodebuild build -scheme axlockd -configuration Release
```

The built executables are in `~/Library/Developer/Xcode/DerivedData/ax-*/Build/Products/Release/`.

## Requirements

- macOS 15.0+ (required for reliable SwiftUI accessibility support)
- **Accessibility permission**: System Settings > Privacy & Security > Accessibility
- **Screen Recording permission** (for screenshots): System Settings > Privacy & Security > Screen Recording

## Quick Start

```bash
# List all displays and running applications
ax ls

# List windows for an app (by PID)
ax ls 1234

# Show UI element tree with depth limit
ax ls 1234 --depth 3

# Click an element by ID
ax click 1234:5678901

# Click at screen coordinates
ax click @100,200

# Type text
ax type "Hello, world!"

# Send keyboard shortcut
ax key cmd+s

# Take a screenshot
ax ls --screenshot /tmp/screen.png
```

## Commands

| Command | Description |
|---------|-------------|
| `ax ls` | List displays, apps, windows, or element trees |
| `ax click <target>` | Click an element or position |
| `ax rightclick <target>` | Right-click an element or position |
| `ax type "text"` | Type text into the focused element |
| `ax key <combo>` | Send keyboard shortcut (e.g., `cmd+s`) |
| `ax scroll <target> <dir> <amount>` | Scroll at position or element |
| `ax action <id> <action>` | Perform accessibility action |
| `ax focus <target>` | Focus an app or element |
| `ax cursor` | Get current mouse position |
| `ax focused` | Get the focused element |
| `ax selection <id>` | Get selected text from element |
| `ax set <id> "value"` | Set element value |
| `ax move <id> --to @x,y` | Move window to position |
| `ax resize <id> WxH` | Resize window |
| `ax drag <from> --to <to>` | Drag from one position to another |
| `ax launch <bundle-id>` | Launch app by bundle ID |
| `ax quit <pid>` | Quit application |
| `ax lock` | Lock human input (for automation) |
| `ax unlock` | Unlock human input |
| `ax help` | Show help and documentation |

## Address Formats

`ax` uses a universal addressing system for targeting elements and positions:

| Format | Example | Description |
|--------|---------|-------------|
| `@x,y` | `@500,300` | Absolute screen coordinates |
| `@x,y+WxH` | `@100,200+400x300` | Screen rectangle |
| `pid` | `1234` | Application by PID |
| `pid:hash` | `1234:5678901` | Element by ID |
| `pid:hash@dx,dy` | `1234:5678901@50,50` | Offset from element |

## Element IDs

Element IDs use the format `<pid>:<hash>` (e.g., `619:1668249066`):

- **PID**: The application's process ID
- **Hash**: A stable hash of the UI element

IDs remain stable while the app is running. Use `ax ls <pid> --depth N` to discover element IDs.

## Examples

### Automate Safari

```bash
# Find Safari's PID
ax ls | jq '.apps[] | select(.name == "Safari") | .pid'

# List Safari's windows
ax ls 1234

# Get the element tree
ax ls 1234 --depth 5

# Click the address bar (using element ID from tree)
ax click 1234:987654321

# Type a URL
ax type "https://example.com"

# Press Enter
ax key return
```

### Take Screenshots

```bash
# Screenshot all displays
ax ls --screenshot /tmp/screen.png

# Screenshot as base64
ax ls --screenshot-base64

# Screenshot a specific window
ax ls 1234:5678901 --screenshot /tmp/window.png

# Screenshot a specific element
ax ls 1234:5678901 --screenshot /tmp/element.png
```

### Lock Input During Automation

```bash
# Lock human input (ax commands still work)
ax lock --timeout 30

# ... run automation commands ...

# Unlock
ax unlock

# Emergency unlock: triple-press Escape
```

## JSON Output

All commands output JSON to stdout. Errors go to stderr.

```bash
# Pretty-print with jq
ax ls | jq

# Extract specific fields
ax ls 1234 --depth 3 | jq '.[0].children[].role'
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Element or application not found |
| 2 | Permission denied |
| 3 | Action failed |
| 4 | Invalid arguments |

## Documentation

```bash
ax help              # General help
ax help roles        # List accessibility roles
ax help actions      # List accessibility actions
ax help attributes   # Explain output fields
ax help keys         # List key names for ax key
ax help --json       # Machine-readable documentation
```

## See Also

| Tool | Language | Primary Purpose | Read Tree | Control Actions | Screenshots | Input Lock | JSON Output |
|------|----------|-----------------|-----------|-----------------|-------------|------------|-------------|
| **[ax](https://github.com/synthemesc/ax)** | Swift | AI agents & automation | ✅ | ✅ | ✅ | ✅ | ✅ |
| [cliclick](https://github.com/BlueM/cliclick) | Objective-C | Mouse/keyboard input | ❌ | ✅ | ❌ | ❌ | ❌ |
| [macapptree](https://github.com/MacPaw/macapptree) | Python | Tree extraction | ✅ | ❌ | ✅ | ❌ | ✅ |
| [pyax](https://github.com/eeejay/pyax) | Python | A11y debugging | ✅ | ❌ | ❌ | ❌ | ✅ |
| [atomacos](https://github.com/daveenguyen/atomacos) | Python | GUI testing | ✅ | ✅ | ❌ | ❌ | ❌ |
| [ax_dump_tree](https://www.chromium.org/developers/accessibility/testing/automated-testing/ax-inspect/) | C++ | Browser a11y testing | ✅ | ❌ | ❌ | ❌ | ❌ |
| [Accessibility Inspector](https://developer.apple.com/documentation/accessibility/accessibility-inspector) | GUI | Manual debugging | ✅ | ✅ | ❌ | ❌ | ❌ |

## License

MIT
