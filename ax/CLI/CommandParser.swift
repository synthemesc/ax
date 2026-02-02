//
//  CommandParser.swift
//  ax
//
//  Manual command-line argument parser (no ArgumentParser dependency).
//
//  Command Format:
//    ax <command> [address] [additional args] [--flags]
//
//  Address Formats:
//    @x,y                    Absolute screen point
//    @x,y+WxH                Absolute screen rect
//    pid:hash                Element by ID
//    pid:hash+WxH            Rect from element's origin
//    pid:hash@dx,dy          Point offset from element
//    pid:hash@dx,dy+WxH      Rect offset from element
//    pid                     Application by PID
//
//  All parsing errors throw AXError.invalidArguments for consistent
//  error handling and exit code 4.
//

import Foundation

/// Manual argument parser (no external dependencies)
struct CommandParser {

    enum Command {
        case help(HelpArgs)
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
        // New commands
        case cursor
        case focused
        case selection(SelectionArgs)
        case set(SetArgs)
        case move(MoveArgs)
        case resize(ResizeArgs)
        case drag(DragArgs)
        case lock(LockArgs)
        case unlock
    }

    struct HelpArgs {
        var topic: String?       // roles, actions, attributes, keys
        var json: Bool = false   // --json
    }

    struct ListArgs {
        var address: Address?    // pid, element, point, or rect
        var depth: Int?          // --depth N
        var screenshot: String?  // --screenshot path
        var screenshotBase64: Bool = false  // --screenshot-base64
        var excludeWindowIds: [UInt32] = []  // --exclude windowId (for screenshot)
    }

    struct ClickArgs {
        var address: Address?    // element or point
    }

    struct TypeArgs {
        var address: Address?    // element (optional)
        var text: String         // text to type
    }

    struct KeyArgs {
        var keys: String         // key combo like "cmd+shift+s"
        var repeatCount: Int = 1 // --repeat N
    }

    struct ScrollArgs {
        var address: Address?    // element or point
        var direction: String    // up, down, left, right
        var amount: Int          // pixels
    }

    struct ActionArgs {
        var address: Address     // element
        var action: String       // action name
    }

    struct FocusArgs {
        var address: Address     // pid or element
    }

    struct LaunchArgs {
        var bundleId: String     // bundle identifier
    }

    struct QuitArgs {
        var pid: Int32           // process id
    }

    // New command args

    struct SelectionArgs {
        var address: Address     // element
    }

    struct SetArgs {
        var address: Address     // element
        var value: String        // value to set
    }

    struct MoveArgs {
        var address: Address     // element to move
        var destination: Address // --to target position
    }

    struct ResizeArgs {
        var address: Address     // element to resize
        var width: Int           // target width
        var height: Int          // target height
    }

    struct DragArgs {
        var from: Address        // start position
        var to: Address          // --to end position
    }

    struct LockArgs {
        var timeout: Int = 60    // --timeout N (seconds, max 300)
    }

    /// Parse command line arguments
    static func parse(_ args: [String]) throws -> Command {
        // Remove program name
        var args = Array(args.dropFirst())

        guard let commandName = args.first else {
            return .help(HelpArgs())
        }

        args.removeFirst()

        switch commandName {
        case "help", "--help", "-h":
            return try .help(parseHelpArgs(args))

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

        // New commands
        case "cursor":
            return .cursor

        case "focused":
            return .focused

        case "selection":
            return try .selection(parseSelectionArgs(args))

        case "set":
            return try .set(parseSetArgs(args))

        case "move":
            return try .move(parseMoveArgs(args))

        case "resize":
            return try .resize(parseResizeArgs(args))

        case "drag":
            return try .drag(parseDragArgs(args))

        case "lock":
            return try .lock(parseLockArgs(args))

        case "unlock":
            return .unlock

        default:
            throw AXError.invalidArguments("Unknown command: \(commandName)")
        }
    }

    // MARK: - Individual Parsers

    private static func parseHelpArgs(_ args: [String]) throws -> HelpArgs {
        var result = HelpArgs()
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--json" {
                result.json = true
            } else if !arg.hasPrefix("-") {
                result.topic = arg
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        return result
    }

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
            } else if arg == "--exclude" {
                i += 1
                guard i < args.count, let windowId = UInt32(args[i]) else {
                    throw AXError.invalidArguments("--exclude requires a window ID number")
                }
                result.excludeWindowIds.append(windowId)
            } else if !arg.hasPrefix("-") {
                result.address = try AddressParser.parse(arg)
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
                // Legacy support: --pos x,y
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--pos requires x,y coordinates")
                }
                // Convert --pos x,y to @x,y address
                result.address = try AddressParser.parse("@" + args[i])
            } else if !arg.hasPrefix("-") {
                result.address = try AddressParser.parse(arg)
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
        // If there are two args, first is address, second is text
        if args.count == 1 {
            return TypeArgs(address: nil, text: args[0])
        } else {
            let address = try AddressParser.parse(args[0])
            return TypeArgs(address: address, text: args[1])
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
        var address: Address?
        var direction: String?
        var amount: Int?
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--pos" || arg == "-p" {
                // Legacy support: --pos x,y
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--pos requires x,y coordinates")
                }
                address = try AddressParser.parse("@" + args[i])
            } else if !arg.hasPrefix("-") {
                // Could be address, direction, or amount
                if ["up", "down", "left", "right"].contains(arg.lowercased()) {
                    direction = arg.lowercased()
                } else if let num = Int(arg), address != nil || direction != nil {
                    // Only treat as amount if we already have address or direction
                    amount = num
                } else {
                    // Try to parse as address
                    address = try AddressParser.parse(arg)
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

        return ScrollArgs(address: address, direction: dir, amount: amt)
    }

    private static func parseActionArgs(_ args: [String]) throws -> ActionArgs {
        guard args.count >= 2 else {
            throw AXError.invalidArguments("action requires element address and action name")
        }

        let address = try AddressParser.parse(args[0])
        return ActionArgs(address: address, action: args[1])
    }

    private static func parseFocusArgs(_ args: [String]) throws -> FocusArgs {
        guard let target = args.first else {
            throw AXError.invalidArguments("focus requires a pid or element address")
        }

        let address = try AddressParser.parse(target)
        return FocusArgs(address: address)
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

    // MARK: - New Command Parsers

    private static func parseSelectionArgs(_ args: [String]) throws -> SelectionArgs {
        guard let target = args.first else {
            throw AXError.invalidArguments("selection requires an element address")
        }

        let address = try AddressParser.parse(target)
        return SelectionArgs(address: address)
    }

    private static func parseSetArgs(_ args: [String]) throws -> SetArgs {
        guard args.count >= 2 else {
            throw AXError.invalidArguments("set requires element address and value")
        }

        let address = try AddressParser.parse(args[0])
        return SetArgs(address: address, value: args[1])
    }

    private static func parseMoveArgs(_ args: [String]) throws -> MoveArgs {
        var address: Address?
        var destination: Address?
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--to" || arg == "-t" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--to requires a destination address")
                }
                destination = try AddressParser.parse(args[i])
            } else if !arg.hasPrefix("-") {
                address = try AddressParser.parse(arg)
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        guard let addr = address else {
            throw AXError.invalidArguments("move requires an element address")
        }
        guard let dest = destination else {
            throw AXError.invalidArguments("move requires --to destination")
        }

        return MoveArgs(address: addr, destination: dest)
    }

    private static func parseResizeArgs(_ args: [String]) throws -> ResizeArgs {
        var address: Address?
        var size: (width: Int, height: Int)?
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--to" || arg == "-t" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--to requires a size (WxH)")
                }
                size = try parseSize(args[i])
            } else if !arg.hasPrefix("-") {
                // Could be address or size
                if arg.lowercased().contains("x") && !arg.contains(":") && !arg.hasPrefix("@") {
                    size = try parseSize(arg)
                } else {
                    address = try AddressParser.parse(arg)
                }
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        guard let addr = address else {
            throw AXError.invalidArguments("resize requires an element address")
        }
        guard let sz = size else {
            throw AXError.invalidArguments("resize requires a size (WxH or --to WxH)")
        }

        return ResizeArgs(address: addr, width: sz.width, height: sz.height)
    }

    private static func parseDragArgs(_ args: [String]) throws -> DragArgs {
        var from: Address?
        var to: Address?
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--to" || arg == "-t" {
                i += 1
                guard i < args.count else {
                    throw AXError.invalidArguments("--to requires a destination address")
                }
                to = try AddressParser.parse(args[i])
            } else if !arg.hasPrefix("-") {
                from = try AddressParser.parse(arg)
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        guard let fromAddr = from else {
            throw AXError.invalidArguments("drag requires a start address")
        }
        guard let toAddr = to else {
            throw AXError.invalidArguments("drag requires --to destination")
        }

        return DragArgs(from: fromAddr, to: toAddr)
    }

    private static func parseLockArgs(_ args: [String]) throws -> LockArgs {
        var result = LockArgs()
        var i = 0

        while i < args.count {
            let arg = args[i]

            if arg == "--timeout" || arg == "-t" {
                i += 1
                guard i < args.count, let timeout = Int(args[i]) else {
                    throw AXError.invalidArguments("--timeout requires a number")
                }
                // Cap timeout at 300 seconds (5 minutes)
                result.timeout = min(timeout, 300)
            } else {
                throw AXError.invalidArguments("Unknown option: \(arg)")
            }

            i += 1
        }

        return result
    }

    // MARK: - Helpers

    private static func parseSize(_ str: String) throws -> (width: Int, height: Int) {
        let lowercased = str.lowercased()
        let parts = lowercased.split(separator: "x")
        guard parts.count == 2,
              let w = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let h = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            throw AXError.invalidArguments("Invalid size format: \(str). Use: WxH (e.g., 800x600)")
        }
        return (w, h)
    }
}
