//
//  CommandParser.swift
//  ax
//
//  Manual command-line argument parser (no ArgumentParser dependency).
//
//  Command Format:
//    ax <command> [positional args] [--flags]
//
//  Argument Patterns:
//    ax ls                       # No args
//    ax ls 1234                  # Positional: PID or element ID
//    ax ls 1234 --depth 3        # Positional + flag with value
//    ax click --pos 100,200      # Flag-only (position as x,y)
//    ax type "hello"             # Positional: text to type
//    ax type 0x123 "hello"       # Two positionals: target + text
//
//  Position Format: x,y (comma-separated integers, no spaces)
//
//  All parsing errors throw AXError.invalidArguments for consistent
//  error handling and exit code 4.
//

import Foundation

/// Manual argument parser (no external dependencies)
struct CommandParser {

    enum Command {
        case help
        case list(ListArgs)
        case click(ClickArgs)
        case rightClick(ClickArgs)
        case type(TypeArgs)
        case key(KeyArgs)
        case scroll(ScrollArgs)
        case action(ActionArgs)
        case focus(FocusArgs)
        case launch(LaunchArgs)
        case quit(QuitArgs)
    }

    struct ListArgs {
        var target: String?      // pid or element id
        var depth: Int?          // --depth N
        var screenshot: String?  // --screenshot path
        var screenshotBase64: Bool = false  // --screenshot-base64
    }

    struct ClickArgs {
        var target: String?      // element id
        var position: (x: Int, y: Int)?  // --pos x,y
    }

    struct TypeArgs {
        var target: String?      // element id (optional)
        var text: String         // text to type
    }

    struct KeyArgs {
        var keys: String         // key combo like "cmd+shift+s"
        var repeatCount: Int = 1 // --repeat N
    }

    struct ScrollArgs {
        var target: String?      // element id
        var position: (x: Int, y: Int)?  // --pos x,y
        var direction: String    // up, down, left, right
        var amount: Int          // pixels
    }

    struct ActionArgs {
        var target: String       // element id
        var action: String       // action name
    }

    struct FocusArgs {
        var target: String       // pid or element id
    }

    struct LaunchArgs {
        var bundleId: String     // bundle identifier
    }

    struct QuitArgs {
        var pid: Int32           // process id
    }

    /// Parse command line arguments
    static func parse(_ args: [String]) throws -> Command {
        // Remove program name
        var args = Array(args.dropFirst())

        guard let commandName = args.first else {
            return .help
        }

        args.removeFirst()

        switch commandName {
        case "help", "--help", "-h":
            return .help

        case "ls", "list":
            return try .list(parseListArgs(args))

        case "click":
            return try .click(parseClickArgs(args))

        case "rightclick", "right-click":
            return try .rightClick(parseClickArgs(args))

        case "type":
            return try .type(parseTypeArgs(args))

        case "key":
            return try .key(parseKeyArgs(args))

        case "scroll":
            return try .scroll(parseScrollArgs(args))

        case "action":
            return try .action(parseActionArgs(args))

        case "focus":
            return try .focus(parseFocusArgs(args))

        case "launch":
            return try .launch(parseLaunchArgs(args))

        case "quit":
            return try .quit(parseQuitArgs(args))

        default:
            throw AXError.invalidArguments("Unknown command: \(commandName)")
        }
    }

    // MARK: - Individual Parsers

    private static func parseListArgs(_ args: [String]) throws -> ListArgs {
        var result = ListArgs()
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--depth" || arg == "-d" {
                i += 1
                guard i < args.count, let depth = Int(args[i]) else {
                    throw AXError.invalidArguments("--depth requires a number")
                }
                result.depth = depth
            } else if arg == "--screenshot" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--screenshot requires a path")
                }
                result.screenshot = args[i]
            } else if arg == "--screenshot-base64" {
                result.screenshotBase64 = true
            } else if !arg.hasPrefix("-") {
                result.target = arg
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        return result
    }

    private static func parseClickArgs(_ args: [String]) throws -> ClickArgs {
        var result = ClickArgs()
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--pos" || arg == "-p" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--pos requires x,y coordinates")
                }
                result.position = try parsePosition(args[i])
            } else if !arg.hasPrefix("-") {
                result.target = arg
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        return result
    }

    private static func parseTypeArgs(_ args: [String]) throws -> TypeArgs {
        guard !args.isEmpty else {
            throw AXError.invalidArguments("type requires text argument")
        }

        // If there's one arg, it's the text
        // If there are two args, first is target, second is text
        if args.count == 1 {
            return TypeArgs(target: nil, text: args[0])
        } else {
            return TypeArgs(target: args[0], text: args[1])
        }
    }

    private static func parseKeyArgs(_ args: [String]) throws -> KeyArgs {
        var keys: String?
        var repeatCount = 1
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--repeat" || arg == "-r" {
                i += 1
                guard i < args.count, let count = Int(args[i]) else {
                    throw AXError.invalidArguments("--repeat requires a number")
                }
                repeatCount = count
            } else if !arg.hasPrefix("-") {
                keys = arg
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        guard let keys = keys else {
            throw AXError.invalidArguments("key requires a key combination")
        }

        return KeyArgs(keys: keys, repeatCount: repeatCount)
    }

    private static func parseScrollArgs(_ args: [String]) throws -> ScrollArgs {
        var target: String?
        var position: (x: Int, y: Int)?
        var direction: String?
        var amount: Int?
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--pos" || arg == "-p" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--pos requires x,y coordinates")
                }
                position = try parsePosition(args[i])
            } else if !arg.hasPrefix("-") {
                // Could be target, direction, or amount
                if ["up", "down", "left", "right"].contains(arg.lowercased()) {
                    direction = arg.lowercased()
                } else if let num = Int(arg) {
                    amount = num
                } else {
                    target = arg
                }
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        guard let dir = direction else {
            throw AXError.invalidArguments("scroll requires a direction (up, down, left, right)")
        }
        guard let amt = amount else {
            throw AXError.invalidArguments("scroll requires an amount")
        }

        return ScrollArgs(target: target, position: position, direction: dir, amount: amt)
    }

    private static func parseActionArgs(_ args: [String]) throws -> ActionArgs {
        guard args.count >= 2 else {
            throw AXError.invalidArguments("action requires element id and action name")
        }

        return ActionArgs(target: args[0], action: args[1])
    }

    private static func parseFocusArgs(_ args: [String]) throws -> FocusArgs {
        guard let target = args.first else {
            throw AXError.invalidArguments("focus requires a pid or element id")
        }

        return FocusArgs(target: target)
    }

    private static func parseLaunchArgs(_ args: [String]) throws -> LaunchArgs {
        guard let bundleId = args.first else {
            throw AXError.invalidArguments("launch requires a bundle identifier")
        }

        return LaunchArgs(bundleId: bundleId)
    }

    private static func parseQuitArgs(_ args: [String]) throws -> QuitArgs {
        guard let pidStr = args.first, let pid = Int32(pidStr) else {
            throw AXError.invalidArguments("quit requires a process id")
        }

        return QuitArgs(pid: pid)
    }

    // MARK: - Helpers

    private static func parsePosition(_ str: String) throws -> (x: Int, y: Int) {
        let parts = str.split(separator: ",")
        guard parts.count == 2,
              let x = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let y = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            throw AXError.invalidArguments("Invalid position format. Use: x,y")
        }
        return (x, y)
    }
}
