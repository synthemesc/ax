//
//  main.swift
//  ax
//
//  macOS Accessibility CLI - Expose the accessibility tree as JSON for AI agents.
//
//  Entry point that:
//  1. Parses command-line arguments (CommandParser)
//  2. Checks accessibility permission (AXIsProcessTrusted)
//  3. Dispatches to appropriate command handler
//  4. Outputs JSON to stdout, errors to stderr
//
//  All commands exit with appropriate codes (see ExitCode.swift):
//  0 = success, 1 = not found, 2 = permission denied, 3 = action failed, 4 = invalid args
//

import Foundation
import ApplicationServices

// MARK: - Permission Check

func checkAccessibilityPermission() {
    let trusted = AXIsProcessTrusted()
    if !trusted {
        Output.error(.permissionDenied)
    }
}

// MARK: - Help Text

let helpText = """
ax - macOS Accessibility CLI

USAGE:
    ax <command> [address] [options]

ADDRESS FORMATS:
    @x,y                    Absolute screen point
    @x,y+WxH                Absolute screen rect
    pid                     Application by PID
    pid:hash                Element by ID
    pid:hash+WxH            Rect from element's origin
    pid:hash@dx,dy          Point offset from element
    pid:hash@dx,dy+WxH      Rect offset from element

COMMANDS:
    ls                      List running applications and displays
    ls <pid>                List windows for an application
    ls <pid:hash>           Show element tree starting from element
    ls @x,y                 Show element at screen coordinates
    ls @x,y+WxH             Show elements within screen rect

    click <address>         Click at element or coordinates
    rightclick <address>    Right-click at element or coordinates

    type "text"             Type text into focused element
    type <address> "text"   Focus element and type text

    key <combo>             Press key combination (e.g., cmd+shift+s)
    key <combo> --repeat n  Repeat key press n times

    scroll <address> <dir> <amt>  Scroll at position (dir: up/down/left/right)

    action <address> <action>     Perform accessibility action on element

    focus <pid>             Activate application
    focus <address>         Focus element

    cursor                  Get current mouse position
    focused                 Get currently focused element
    selection <address>     Get selected text from element

    set <address> "value"   Set element's value
    move <address> --to @x,y      Move window/element to position
    resize <address> WxH          Resize window/element

    drag <address> --to <address> Drag from one position to another

    launch <bundle-id>      Launch application by bundle identifier
    quit <pid>              Quit application by process id

    lock                    Lock human HID input (ax commands still work)
    unlock                  Unlock human HID input

    help                    Show this help
    help roles              List accessibility roles
    help actions            List accessibility actions
    help attributes         Explain output fields
    help keys               List key names for ax key command
    help --json             Machine-readable documentation

OPTIONS:
    --depth, -d <n>         Limit tree traversal depth
    --to, -t <address>      Destination for move/drag commands
    --repeat, -r <n>        Repeat count for key presses
    --screenshot <path>     Save screenshot to file (with ls)
    --screenshot-base64     Include screenshot as base64 in JSON (with ls)
    --exclude <windowId>    Exclude window from screenshot (with ls)
    --timeout, -t <n>       Lock timeout in seconds (max 300, with lock)
    --help, -h              Show this help

EXIT CODES:
    0   Success
    1   Element or application not found
    2   Accessibility permission denied
    3   Action failed
    4   Invalid arguments

ELEMENT IDs:
    IDs have format: <pid>:<hash> (e.g., 619:1668249066)
    IDs are stable across invocations while the app is running.

EXAMPLES:
    ax ls                           # List all apps and displays
    ax ls 1234                      # List windows for app with pid 1234
    ax ls 1234:5678901              # Show element tree from element ID
    ax ls @500,300                  # Show element at screen coordinates
    ax click 1234:5678901           # Click element by ID
    ax click @100,200               # Click at screen coordinates
    ax click 1234:5678901@50,50     # Click at offset from element
    ax type "Hello, world!"         # Type into focused element
    ax key cmd+s                    # Press Cmd+S
    ax cursor                       # Get mouse position
    ax focused                      # Get focused element
    ax selection 1234:5678901       # Get selected text
    ax set 1234:5678901 "new text"  # Set element value
    ax move 1234:5678901 --to @100,100  # Move window
    ax resize 1234:5678901 800x600  # Resize window
    ax drag @100,200 --to @300,400  # Drag from one point to another
    ax launch com.apple.Safari      # Launch Safari
    ax lock                         # Lock human input (ax commands still work)
    ax lock --timeout 30            # Lock with 30 second timeout
    ax unlock                       # Unlock input
"""

// MARK: - Main

func main() {
    do {
        let command = try CommandParser.parse(CommandLine.arguments)

        switch command {
        case .help(let args):
            if args.json || args.topic != nil {
                HelpCommand.run(args: HelpCommand.HelpArgs(
                    topic: args.topic.flatMap { HelpCommand.Topic(rawValue: $0) },
                    json: args.json
                ))
            } else {
                print(helpText)
                exit(0)
            }

        case .list(let args):
            checkAccessibilityPermission()
            ListCommand.run(args: args)

        case .click(let args):
            checkAccessibilityPermission()
            ClickCommand.run(args: args, rightClick: false)

        case .rightClick(let args):
            checkAccessibilityPermission()
            ClickCommand.run(args: args, rightClick: true)

        case .type(let args):
            checkAccessibilityPermission()
            TypeCommand.run(args: args)

        case .key(let args):
            checkAccessibilityPermission()
            KeyCommand.run(args: args)

        case .scroll(let args):
            checkAccessibilityPermission()
            ScrollCommand.run(args: args)

        case .action(let args):
            checkAccessibilityPermission()
            ActionCommand.run(args: args)

        case .focus(let args):
            checkAccessibilityPermission()
            FocusCommand.run(args: args)

        case .launch(let args):
            LaunchCommand.run(args: args)

        case .quit(let args):
            QuitCommand.run(args: args)

        // New commands
        case .cursor:
            CursorCommand.run()

        case .focused:
            checkAccessibilityPermission()
            FocusedCommand.run()

        case .selection(let args):
            checkAccessibilityPermission()
            SelectionCommand.run(args: args)

        case .set(let args):
            checkAccessibilityPermission()
            SetCommand.run(args: args)

        case .move(let args):
            checkAccessibilityPermission()
            MoveCommand.run(args: args)

        case .resize(let args):
            checkAccessibilityPermission()
            ResizeCommand.run(args: args)

        case .drag(let args):
            checkAccessibilityPermission()
            DragCommand.run(args: args)

        case .lock(let args):
            checkAccessibilityPermission()
            LockCommand.run(args: args)

        case .unlock:
            UnlockCommand.run()
        }
    } catch let error as AXError {
        Output.error(error)
    } catch {
        Output.error(error.localizedDescription, exitCode: .actionFailed)
    }
}

main()
