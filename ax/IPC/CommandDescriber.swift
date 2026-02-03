//
//  CommandDescriber.swift
//  ax
//
//  Generates human-readable descriptions of ax commands for display in axlockd.
//

import Foundation

/// Generates human-readable descriptions of ax commands for display in axlockd.
struct CommandDescriber {

    static func describe(_ command: CommandParser.Command) -> (command: String, description: String) {
        switch command {
        case .help:
            return ("help", "showing help")

        case .list(let args):
            return describeList(args)

        case .click(let args):
            return describeClick(args, rightClick: false)

        case .rightClick(let args):
            return describeClick(args, rightClick: true)

        case .type(let args):
            return describeType(args)

        case .key(let args):
            return describeKey(args)

        case .scroll(let args):
            return describeScroll(args)

        case .action(let args):
            return describeAction(args)

        case .focus(let args):
            return describeFocus(args)

        case .launch(let args):
            return ("launch", "launching \(bundleName(args.bundleId))")

        case .quit(let args):
            return ("quit", "quitting app \(args.pid)")

        case .cursor:
            return ("cursor", "getting cursor position")

        case .focused:
            return ("focused", "getting focused element")

        case .selection(let args):
            return ("selection", "getting selection from \(describeAddress(args.address))")

        case .set(let args):
            let valuePreview = String(args.value.prefix(20))
            let suffix = args.value.count > 20 ? "..." : ""
            return ("set", "setting value to \"\(valuePreview)\(suffix)\"")

        case .move(let args):
            return ("move", "moving to \(describeAddress(args.destination))")

        case .resize(let args):
            return ("resize", "resizing to \(args.width)x\(args.height)")

        case .drag(let args):
            return ("drag", "dragging from \(describeAddress(args.from)) to \(describeAddress(args.to))")

        case .lock:
            return ("lock", "locking input")

        case .unlock:
            return ("unlock", "unlocking input")
        }
    }

    // MARK: - Private Helpers

    private static func describeList(_ args: CommandParser.ListArgs) -> (String, String) {
        if let screenshot = args.screenshot {
            return ("screenshot", "taking screenshot to \(URL(fileURLWithPath: screenshot).lastPathComponent)")
        }
        if args.screenshotBase64 {
            return ("screenshot", "taking screenshot")
        }
        if let address = args.address {
            return ("ls", "listing \(describeAddress(address))")
        }
        return ("ls", "listing apps")
    }

    private static func describeClick(_ args: CommandParser.ClickArgs, rightClick: Bool) -> (String, String) {
        let verb = rightClick ? "right-clicking" : "clicking"
        if let address = args.address {
            return (rightClick ? "rightclick" : "click", "\(verb) \(describeAddress(address))")
        }
        return (rightClick ? "rightclick" : "click", verb)
    }

    private static func describeType(_ args: CommandParser.TypeArgs) -> (String, String) {
        let charCount = args.text.count
        return ("type", "typing \(charCount) character\(charCount == 1 ? "" : "s")")
    }

    private static func describeKey(_ args: CommandParser.KeyArgs) -> (String, String) {
        if args.repeatCount > 1 {
            return ("key", "pressing \(args.keys) x\(args.repeatCount)")
        }
        return ("key", "pressing \(args.keys)")
    }

    private static func describeScroll(_ args: CommandParser.ScrollArgs) -> (String, String) {
        if let address = args.address {
            return ("scroll", "scrolling \(args.direction) \(args.amount) at \(describeAddress(address))")
        }
        return ("scroll", "scrolling \(args.direction) \(args.amount)")
    }

    private static func describeAction(_ args: CommandParser.ActionArgs) -> (String, String) {
        return ("action", "performing \(args.action) on \(describeAddress(args.address))")
    }

    private static func describeFocus(_ args: CommandParser.FocusArgs) -> (String, String) {
        return ("focus", "focusing \(describeAddress(args.address))")
    }

    private static func describeAddress(_ address: Address) -> String {
        switch address {
        case .absolutePoint(let x, let y):
            return "@\(x),\(y)"
        case .absoluteRect(let x, let y, let w, let h):
            return "@\(x),\(y)+\(w)x\(h)"
        case .pid(let pid):
            return "app \(pid)"
        case .element(let pid, let hash):
            return "\(pid):\(hash)"
        case .elementOffset(let pid, let hash, let dx, let dy):
            return "\(pid):\(hash)@\(dx),\(dy)"
        case .elementOffsetRect(let pid, let hash, let dx, let dy, let w, let h):
            return "\(pid):\(hash)@\(dx),\(dy)+\(w)x\(h)"
        case .elementRect(let pid, let hash, let w, let h):
            return "\(pid):\(hash)+\(w)x\(h)"
        }
    }

    private static func bundleName(_ bundleId: String) -> String {
        // Extract app name from bundle ID (e.g., "com.apple.Safari" -> "Safari")
        if let lastComponent = bundleId.split(separator: ".").last {
            return String(lastComponent)
        }
        return bundleId
    }
}
