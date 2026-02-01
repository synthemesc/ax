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
    ax <command> [options]

COMMANDS:
    ls                      List running applications
    ls <pid>                List windows for an application
    ls <id>                 Show element tree starting from element
    ls <id> --depth <n>     Limit tree depth

    click <id>              Click an element (uses AXPress or center click)
    click --pos x,y         Click at screen coordinates

    rightclick <id>         Right-click an element
    rightclick --pos x,y    Right-click at screen coordinates

    type "text"             Type text into focused element
    type <id> "text"        Focus element and type text

    key <combo>             Press key combination (e.g., cmd+shift+s)
    key <combo> --repeat n  Repeat key press n times

    scroll <id> <dir> <amt> Scroll element (dir: up/down/left/right)
    scroll --pos x,y <dir> <amt>

    action <id> <action>    Perform accessibility action on element

    focus <pid>             Activate application
    focus <id>              Focus element

    launch <bundle-id>      Launch application by bundle identifier

    quit <pid>              Quit application by process id

OPTIONS:
    --depth, -d <n>         Limit tree traversal depth
    --pos, -p <x,y>         Screen coordinates
    --repeat, -r <n>        Repeat count for key presses
    --screenshot <path>     Save screenshot to file (with ls)
    --screenshot-base64     Include screenshot as base64 in JSON (with ls)
    --help, -h              Show this help

EXIT CODES:
    0   Success
    1   Element or application not found
    2   Accessibility permission denied
    3   Action failed
    4   Invalid arguments

ELEMENT IDs:
    IDs have format: <pid>-<hash> (e.g., 619-1668249066)
    IDs are stable across invocations while the app is running.

EXAMPLES:
    ax ls                           # List all apps
    ax ls 1234                      # List windows for app with pid 1234
    ax ls 1234-5678901              # Show element tree from element ID
    ax ls 1234 --depth 3            # Show windows with 3 levels of children
    ax click 1234-5678901           # Click element by ID
    ax click --pos 100,200          # Click at coordinates
    ax type "Hello, world!"         # Type into focused element
    ax key cmd+s                    # Press Cmd+S
    ax launch com.apple.Safari      # Launch Safari
"""

// MARK: - Main

func main() {
    do {
        let command = try CommandParser.parse(CommandLine.arguments)

        switch command {
        case .help:
            print(helpText)
            exit(0)

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
        }
    } catch let error as AXError {
        Output.error(error)
    } catch {
        Output.error(error.localizedDescription, exitCode: .actionFailed)
    }
}

main()
