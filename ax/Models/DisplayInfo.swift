//
//  DisplayInfo.swift
//  ax
//

import Foundation
import AppKit

/// Information about a display
struct DisplayInfo: Codable {
    let id: UInt32
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let scale: Double
    let main: Bool?

    init(screen: NSScreen, isMain: Bool) {
        self.id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 ?? 0
        self.x = Int(screen.frame.origin.x)
        self.y = Int(screen.frame.origin.y)
        self.width = Int(screen.frame.size.width)
        self.height = Int(screen.frame.size.height)
        self.scale = screen.backingScaleFactor
        self.main = isMain ? true : nil
    }

    /// Get all displays
    static func all() -> [DisplayInfo] {
        let mainScreen = NSScreen.main
        return NSScreen.screens.map { screen in
            DisplayInfo(screen: screen, isMain: screen == mainScreen)
        }
    }

    /// Find which display contains the given point
    static func displayContaining(point: CGPoint) -> UInt32? {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32
            }
        }
        return nil
    }

    /// Find which display contains the given rect (by largest overlap or origin)
    static func displayContaining(rect: CGRect) -> UInt32? {
        // First try: check which display contains the window's origin
        if let display = displayContaining(point: rect.origin) {
            return display
        }

        // Fallback: find display with largest overlap
        var bestDisplay: UInt32?
        var bestOverlap: CGFloat = 0

        for screen in NSScreen.screens {
            let overlap = screen.frame.intersection(rect)
            if !overlap.isNull {
                let overlapArea = overlap.width * overlap.height
                if overlapArea > bestOverlap {
                    bestOverlap = overlapArea
                    bestDisplay = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32
                }
            }
        }

        return bestDisplay
    }
}

/// Result for top-level app list including display info
struct AppListResult: Codable {
    let displays: [DisplayInfo]
    let apps: [AppInfo]
}
