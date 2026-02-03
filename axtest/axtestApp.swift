//
//  axtestApp.swift
//  axtest
//
//  Test harness app for ax CLI verification.
//
//  IMPORTANT: Requires macOS 15.0+
//  On macOS 14, SwiftUI windows don't properly expose their content to the
//  accessibility tree - only the menu bar elements are visible, not buttons,
//  text fields, or other window content. This was fixed in macOS 15.
//

import SwiftUI

@main
struct axtestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 600, height: 700)
    }
}
