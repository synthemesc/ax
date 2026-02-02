//
//  ScreenCapture.swift
//  ax
//
//  Screenshot capture using ScreenCaptureKit (macOS 12.3+).
//
//  NOTE: CGWindowListCreateImage is deprecated in macOS 26+, so we use
//  ScreenCaptureKit instead. This requires Screen Recording permission.
//
//  Permission Flow:
//  1. CGPreflightScreenCaptureAccess() - check if already granted
//  2. CGRequestScreenCaptureAccess() - show system dialog if not
//  3. User must grant in System Settings > Privacy > Screen Recording
//
//  Capture Methods:
//  - captureScreen() - Full main display
//  - captureApp(pid:) - Bounding rect of all windows for a specific app
//
//  The async APIs are wrapped with DispatchSemaphore for synchronous CLI use.
//  Images are saved as PNG or returned as base64-encoded strings.
//

import Foundation
import CoreGraphics
import AppKit
import ScreenCaptureKit
import UniformTypeIdentifiers

/// Screen capture utilities using ScreenCaptureKit
struct ScreenCapture {

    /// Check if screen capture permission is granted
    static func checkPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    /// Request screen capture permission (shows system dialog)
    static func requestPermission() -> Bool {
        return CGRequestScreenCaptureAccess()
    }

    /// Capture the entire screen (main display)
    /// - Parameter excluding: Window IDs to exclude from capture (e.g., overlay windows)
    static func captureScreen(excluding: [CGWindowID] = []) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        guard let display = content.displays.first else {
            throw AXError.actionFailed("No displays found")
        }

        // Filter out excluded windows
        let excludeWindows = content.windows.filter { excluding.contains(CGWindowID($0.windowID)) }
        let filter = SCContentFilter(display: display, excludingWindows: excludeWindows)
        let config = SCStreamConfiguration()
        config.width = Int(display.width) * 2  // Retina
        config.height = Int(display.height) * 2
        config.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return image
    }

    /// Capture all windows belonging to a specific PID
    static func captureApp(pid: pid_t) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        // Find windows for this app
        let appWindows = content.windows.filter { $0.owningApplication?.processID == pid }

        guard !appWindows.isEmpty else {
            throw AXError.actionFailed("No windows found for pid \(pid)")
        }

        guard let display = content.displays.first else {
            throw AXError.actionFailed("No displays found")
        }

        // Create filter with just this app's windows
        let filter = SCContentFilter(display: display, including: appWindows)

        // Calculate bounding rect
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        for window in appWindows {
            let frame = window.frame
            minX = min(minX, frame.minX)
            minY = min(minY, frame.minY)
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }

        let config = SCStreamConfiguration()
        config.sourceRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        config.width = Int(maxX - minX) * 2  // Retina
        config.height = Int(maxY - minY) * 2
        config.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return image
    }

    /// Capture a rectangular region of the screen
    /// - Parameters:
    ///   - rect: The rect in screen coordinates
    ///   - excluding: Window IDs to exclude from capture
    static func captureRect(_ rect: CGRect, excluding: [CGWindowID] = []) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        guard let display = content.displays.first else {
            throw AXError.actionFailed("No displays found")
        }

        // Filter out excluded windows
        let excludeWindows = content.windows.filter { excluding.contains(CGWindowID($0.windowID)) }
        let filter = SCContentFilter(display: display, excludingWindows: excludeWindows)
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.width) * 2   // Retina
        config.height = Int(rect.height) * 2
        config.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return image
    }

    /// Capture an element by cropping to its frame
    /// - Parameters:
    ///   - frame: The element's frame in screen coordinates
    ///   - pid: The process ID of the app containing the element
    static func captureElement(frame: CGRect, pid: pid_t) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        // Find windows for this app
        let appWindows = content.windows.filter { $0.owningApplication?.processID == pid }

        guard !appWindows.isEmpty else {
            throw AXError.actionFailed("No windows found for pid \(pid)")
        }

        guard let display = content.displays.first else {
            throw AXError.actionFailed("No displays found")
        }

        // Create filter with just this app's windows
        let filter = SCContentFilter(display: display, including: appWindows)

        // Configure to capture just the element's region
        let config = SCStreamConfiguration()
        config.sourceRect = frame
        config.width = Int(frame.width) * 2   // Retina
        config.height = Int(frame.height) * 2
        config.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return image
    }

    /// Save a CGImage to a file
    static func save(_ image: CGImage, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)

        guard let destination = destination else {
            throw AXError.actionFailed("Failed to create image destination at \(path)")
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw AXError.actionFailed("Failed to write image to \(path)")
        }
    }

    /// Convert a CGImage to PNG data
    static func pngData(_ image: CGImage) -> Data? {
        let bitmap = NSBitmapImageRep(cgImage: image)
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Convert a CGImage to base64-encoded PNG string
    static func base64PNG(_ image: CGImage) -> String? {
        guard let data = pngData(image) else { return nil }
        return data.base64EncodedString()
    }
}
