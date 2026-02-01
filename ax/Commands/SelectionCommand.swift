//
//  SelectionCommand.swift
//  ax
//

import Foundation
import ApplicationServices

/// Handles the `ax selection` command - returns selected text from an element
struct SelectionCommand {

    private struct SelectionResult: Encodable {
        let text: String?
        let range: [Int]?  // [location, length]
    }

    static func run(args: CommandParser.SelectionArgs) {
        do {
            let element = try AddressResolver.resolveElement(args.address)

            // Get selected text
            let selectedText: String? = try element.attribute(kAXSelectedTextAttribute)

            // Get selected text range
            var range: [Int]? = nil
            if let cfRange: CFRange = try element.attribute(kAXSelectedTextRangeAttribute) {
                range = [Int(cfRange.location), Int(cfRange.length)]
            }

            Output.json(SelectionResult(text: selectedText, range: range))
        } catch let error as AXError {
            Output.error(error)
        } catch {
            Output.error(.actionFailed(error.localizedDescription))
        }
    }
}
