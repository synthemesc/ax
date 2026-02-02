//
//  EventTap.swift
//  axlockd
//
//  CGEventTap wrapper that suppresses human HID input while allowing
//  ax-generated events (marked with userData) to pass through.
//  Implements triple-Escape escape hatch for safety.
//

import Foundation
import CoreGraphics
import Carbon.HIToolbox

/// Event tap that filters human input while allowing programmatic events
class EventTap {

    /// Marker value that identifies ax-generated events
    static let eventMarker: Int64 = 0x4158304158  // "AX0AX" in hex - matches MouseEvents/KeyboardEvents

    /// Callback when triple-Escape is detected
    var onTripleEscape: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Escape key timestamps for triple-escape detection
    private var escapeTimestamps: [Date] = []

    /// Whether the tap is currently active
    private(set) var isActive: Bool = false

    init() {}

    /// Start the event tap
    /// - Returns: true if tap was created successfully
    func start() -> Bool {
        // Events to intercept - build mask incrementally to help type checker
        var eventMask: CGEventMask = 0
        eventMask |= (1 << CGEventType.keyDown.rawValue)
        eventMask |= (1 << CGEventType.keyUp.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDown.rawValue)
        eventMask |= (1 << CGEventType.leftMouseUp.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDown.rawValue)
        eventMask |= (1 << CGEventType.rightMouseUp.rawValue)
        eventMask |= (1 << CGEventType.mouseMoved.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.scrollWheel.rawValue)

        // Create the event tap
        // We use Unmanaged to pass self to the callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let tap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()
                return tap.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            return false
        }

        eventTap = tap

        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true

        return true
    }

    /// Stop the event tap
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        isActive = false
    }

    /// Handle an intercepted event
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {

        // Check if the tap was disabled (system can disable it if events back up)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Re-enable the tap
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Check if this is an ax-generated event (has our marker)
        let userData = event.getIntegerValueField(.eventSourceUserData)
        if userData == EventTap.eventMarker {
            // This is a programmatic event from ax - let it through
            return Unmanaged.passUnretained(event)
        }

        // Check for Escape key (for triple-escape escape hatch)
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == Int64(kVK_Escape) {
                checkTripleEscape()
            }
        }

        // Suppress the human input event
        return nil
    }

    /// Check if we've received three Escape presses within 1 second
    private func checkTripleEscape() {
        let now = Date()

        // Add current timestamp
        escapeTimestamps.append(now)

        // Remove timestamps older than 1 second
        escapeTimestamps = escapeTimestamps.filter { now.timeIntervalSince($0) < 1.0 }

        // Check if we have 3 or more
        if escapeTimestamps.count >= 3 {
            escapeTimestamps.removeAll()
            onTripleEscape?()
        }
    }
}
