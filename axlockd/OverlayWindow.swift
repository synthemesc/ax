//
//  OverlayWindow.swift
//  axlockd
//
//  Semi-transparent overlay window that provides visual feedback
//  when input is locked. One window per screen, ignores mouse events.
//
//  NOTE: The statusLabel uses setAccessibilityIdentifier("ax_lock_status") and
//  setAccessibilityValue() for dynamic updates. This requires macOS 15.0+ to
//  work reliably - on macOS 14, window content isn't properly exposed to the
//  accessibility tree.
//

import AppKit

/// Overlay window that shows lock status
class OverlayWindow: NSWindow {

    private var titleLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var pulseTimer: Timer?

    init(screen: NSScreen) {
        // Cover the entire screen
        let frame = screen.frame

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        self.level = .statusBar + 1
        self.backgroundColor = NSColor.black.withAlphaComponent(0.4)
        self.isOpaque = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = false

        setupContent()
        startPulseAnimation()
    }

    private func setupContent() {
        guard let contentView = self.contentView else { return }

        // Container for centered content
        let container = NSView(frame: contentView.bounds)
        container.autoresizingMask = [.width, .height]
        contentView.addSubview(container)

        // Title label
        titleLabel = NSTextField(labelWithString: "ax is working")
        titleLabel.font = NSFont.systemFont(ofSize: 48, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        // Status label (shows current command)
        statusLabel = NSTextField(labelWithString: "waiting for commands...")
        statusLabel.font = NSFont.systemFont(ofSize: 24, weight: .regular)
        statusLabel.textColor = .white
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.setAccessibilityIdentifier("ax_lock_status")
        container.addSubview(statusLabel)

        // Subtitle label
        subtitleLabel = NSTextField(labelWithString: "Triple-press Escape to cancel")
        subtitleLabel.font = NSFont.systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitleLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Title above center
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),

            // Status below title
            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -40),

            // Subtitle below status
            subtitleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16)
        ])
    }

    /// Update the status text displayed below the title.
    /// - Parameter text: The status text to display (e.g., "clicking at 500, 400")
    func updateStatus(_ text: String) {
        statusLabel.stringValue = text
        statusLabel.setAccessibilityValue(text)
        // Force layout refresh
        statusLabel.invalidateIntrinsicContentSize()
        statusLabel.needsDisplay = true
        statusLabel.superview?.needsLayout = true
        statusLabel.superview?.layoutSubtreeIfNeeded()
        // Notify accessibility that the value changed
        NSAccessibility.post(element: statusLabel as Any, notification: .valueChanged)
    }

    private func startPulseAnimation() {
        // Subtle pulse animation on the title
        var increasing = true
        var alpha: CGFloat = 1.0

        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if increasing {
                alpha += 0.02
                if alpha >= 1.0 {
                    alpha = 1.0
                    increasing = false
                }
            } else {
                alpha -= 0.02
                if alpha <= 0.6 {
                    alpha = 0.6
                    increasing = true
                }
            }

            self.titleLabel.textColor = NSColor.white.withAlphaComponent(alpha)
        }
    }

    func stopAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = nil
    }

    deinit {
        stopAnimation()
    }
}

/// Manager for creating overlay windows on all screens
class OverlayManager {

    private var windows: [OverlayWindow] = []

    /// Create overlay windows on all screens
    /// - Returns: Array of window IDs (CGWindowID)
    func createOverlays() -> [CGWindowID] {
        var windowIds: [CGWindowID] = []

        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            window.orderFrontRegardless()
            windows.append(window)

            // Get the CGWindowID
            let windowId = CGWindowID(window.windowNumber)
            windowIds.append(windowId)
        }

        return windowIds
    }

    /// Close all overlay windows
    func closeOverlays() {
        for window in windows {
            window.stopAnimation()
            window.close()
        }
        windows.removeAll()
    }

    /// Update the status text on all overlay windows.
    /// - Parameter text: The status text to display
    func updateStatus(_ text: String) {
        for window in windows {
            window.updateStatus(text)
        }
    }
}
