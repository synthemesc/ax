//
//  Output.swift
//  ax
//

import Foundation

/// Handles JSON output to stdout and error output to stderr
struct Output {

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let compactEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// Print a Codable value as JSON to stdout
    static func json<T: Encodable>(_ value: T, compact: Bool = false) {
        do {
            let enc = compact ? compactEncoder : encoder
            let data = try enc.encode(value)
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        } catch {
            printError("Failed to encode JSON: \(error)")
        }
    }

    /// Print an error message to stderr
    static func printError(_ message: String) {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }

    /// Print an AXError and exit with appropriate code
    static func error(_ error: AXError) -> Never {
        printError(error.message)
        error.exitCode.exit()
    }

    /// Print a generic error and exit
    static func error(_ message: String, exitCode: ExitCode = .actionFailed) -> Never {
        printError(message)
        exitCode.exit()
    }
}
