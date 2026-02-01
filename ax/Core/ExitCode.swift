//
//  ExitCode.swift
//  ax
//

import Foundation

enum ExitCode: Int32 {
    case success = 0
    case notFound = 1
    case permissionDenied = 2
    case actionFailed = 3
    case invalidArguments = 4

    func exit() -> Never {
        Foundation.exit(rawValue)
    }
}
