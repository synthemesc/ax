//
//  AXError.swift
//  ax
//
//  Error types for the ax CLI with exit code mapping.
//
//  Error Flow:
//  1. Code throws AXError (or AXError wraps system AXError codes)
//  2. Output.error() prints message to stderr
//  3. exitCode property maps to ExitCode enum
//  4. Process exits with numeric code
//
//  AXError.Code wraps raw AXError values from ApplicationServices:
//  - .invalidUIElement (-25202): Element no longer exists
//  - .attributeUnsupported (-25205): Attribute not available
//  - .actionUnsupported (-25206): Action not available
//  - .apiDisabled (-25211): Accessibility not enabled
//  - .noValue (-25212): Attribute exists but has no value
//

import Foundation
import ApplicationServices

enum AXError: Error {
    case notFound(String)
    case permissionDenied
    case actionFailed(String)
    case invalidArguments(String)
    case apiError(AXError.Code)

    enum Code: Int {
        case failure = -25200
        case illegalArgument = -25201
        case invalidUIElement = -25202
        case invalidUIElementObserver = -25203
        case cannotComplete = -25204
        case attributeUnsupported = -25205
        case actionUnsupported = -25206
        case notificationUnsupported = -25207
        case notImplemented = -25208
        case notificationAlreadyRegistered = -25209
        case notificationNotRegistered = -25210
        case apiDisabled = -25211
        case noValue = -25212
        case parameterizedAttributeUnsupported = -25213
        case notEnoughPrecision = -25214

        init?(rawValue: Int32) {
            self.init(rawValue: Int(rawValue))
        }
    }

    var exitCode: ExitCode {
        switch self {
        case .notFound:
            return .notFound
        case .permissionDenied:
            return .permissionDenied
        case .actionFailed:
            return .actionFailed
        case .invalidArguments:
            return .invalidArguments
        case .apiError(let code):
            switch code {
            case .invalidUIElement:
                return .notFound
            case .apiDisabled:
                return .permissionDenied
            case .attributeUnsupported, .actionUnsupported, .noValue:
                return .notFound
            default:
                return .actionFailed
            }
        }
    }

    var message: String {
        switch self {
        case .notFound(let detail):
            return "Not found: \(detail)"
        case .permissionDenied:
            return "Accessibility permission denied. Grant access in System Settings > Privacy & Security > Accessibility."
        case .actionFailed(let detail):
            return "Action failed: \(detail)"
        case .invalidArguments(let detail):
            return "Invalid arguments: \(detail)"
        case .apiError(let code):
            return "Accessibility API error: \(code)"
        }
    }
}
