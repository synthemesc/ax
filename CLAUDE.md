# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native macOS command-line tool written in Swift. The project uses Xcode's build system (xcodebuild).

## Build Commands

```bash
# Build (Debug)
xcodebuild build -scheme ax -configuration Debug

# Build (Release)
xcodebuild build -scheme ax -configuration Release

# Clean
xcodebuild clean -scheme ax
```

The built executable is located in the derived data directory. To find and run it:
```bash
xcodebuild build -scheme ax -configuration Debug 2>&1 | grep -A1 "BUILD SUCCEEDED"
# Or locate via: find ~/Library/Developer/Xcode/DerivedData -name "ax" -type f -perm +111
```

## Architecture

- **Entry point:** `ax/main.swift`
- **Build system:** Xcode project (`ax.xcodeproj`)
- **Target:** macOS 26.2+, Swift 5.0
- **Dependencies:** Foundation framework only (no external packages)

## Build Configuration Notes

- Hardened runtime is enabled
- Strict compiler warnings are enabled (unreachable code, null conversions, etc.)
- Swift upcoming features enabled: member import visibility, approachable concurrency
- Whole module optimization in Release builds
