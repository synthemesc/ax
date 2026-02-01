//
//  ElementInfo.swift
//  ax
//

import Foundation

/// Information about an accessibility element
struct ElementInfo: Codable {
    let id: String
    let role: String?
    let subrole: String?
    let title: String?
    let description: String?
    let value: String?
    let label: String?
    let help: String?
    let identifier: String?
    let frame: FrameInfo?
    let enabled: Bool?
    let focused: Bool?
    let actions: [String]?
    let children: [ElementInfo]?
}
