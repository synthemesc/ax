//
//  AppInfo.swift
//  ax
//

import Foundation

/// Information about a running application
struct AppInfo: Codable {
    let pid: Int32
    let name: String?
    let bundleId: String?

    enum CodingKeys: String, CodingKey {
        case pid
        case name
        case bundleId = "bundle_id"
    }
}
