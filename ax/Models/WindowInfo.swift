//
//  WindowInfo.swift
//  ax
//

import Foundation
import CoreGraphics

/// Information about a window
struct WindowInfo: Codable {
    let id: String
    let title: String?
    let frame: FrameInfo?
    let main: Bool?
    let focused: Bool?
    let display: UInt32?

    init(id: String, title: String?, frame: CGRect?, main: Bool?, focused: Bool?) {
        self.id = id
        self.title = title
        self.frame = frame.map(FrameInfo.init)
        self.main = main == true ? true : nil
        self.focused = focused == true ? true : nil
        self.display = frame.flatMap { DisplayInfo.displayContaining(rect: $0) }
    }
}

/// Frame information (origin + size)
struct FrameInfo: Codable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(rect: CGRect) {
        self.x = Int(rect.origin.x)
        self.y = Int(rect.origin.y)
        self.width = Int(rect.size.width)
        self.height = Int(rect.size.height)
    }
}
