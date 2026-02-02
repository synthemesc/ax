//
//  OverlayWindow.swift
//  axlockd
//
//  Semi-transparent overlay window that provides visual feedback
//  when input is locked. One window per screen, ignores mouse events.
//

import AppKit

/// Overlay window that shows lock status
class OverlayWindow: NSWindow {

    private var titleLabel: NSTextField!
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

        // Subtitle label
        subtitleLabel = NSTextField(labelWithString: "Triple-press Escape to cancel")
        subtitleLabel.font = NSFont.systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitleLabel)

        // Center the labels
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -20),

            subtitleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16)
        ])
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
}
