//
//  LockNotifier.swift
//  ax
//
//  Sends fire-and-forget notifications to axlockd about command execution.
//  All operations are fire-and-forget - failures never block or fail ax commands.
//

import Foundation

/// Sends notifications to axlockd about command execution.
/// All operations are fire-and-forget - failures never block ax commands.
struct LockNotifier {

    static let socketPath = "/tmp/ax-lock.sock"

    /// Notify axlockd of command execution.
    /// - Parameters:
    ///   - command: Command name (e.g., "click", "type", "key")
    ///   - description: Human-readable description (e.g., "clicking at 500, 400")
    static func notify(command: String, description: String) {
        // Early exit if lock not active (avoids socket overhead)
        guard LockState.isLocked() != nil else { return }

        // Create socket
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return }
        defer { close(fd) }

        // Disable SIGPIPE on this socket - if server closes, send() returns error instead of signal
        var noSigPipe: Int32 = 1
        _ = setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

        // Set send timeout to prevent blocking for too long
        var timeout = timeval(tv_sec: 0, tv_usec: 50_000)  // 50ms
        _ = setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        // Connect
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        socketPath.withCString { ptr in
            _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { dest in
                strcpy(dest, ptr)
            }
        }

        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                connect(fd, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectResult >= 0 else { return }

        // Build and send message
        let message: [String: Any] = [
            "type": "command",
            "command": command,
            "description": description
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              var jsonString = String(data: data, encoding: .utf8) else {
            return
        }

        jsonString += "\n"
        _ = jsonString.withCString { ptr in
            send(fd, ptr, strlen(ptr), 0)
        }
    }
}
