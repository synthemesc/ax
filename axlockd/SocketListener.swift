//
//  SocketListener.swift
//  axlockd
//
//  Listens for incoming command notifications from ax on a Unix domain socket.
//  Messages are JSON objects with a "description" field that gets displayed
//  in the overlay window.
//

import Foundation

/// Listens for incoming command notifications from ax on a Unix domain socket.
class SocketListener {

    static let socketPath = "/tmp/ax-lock.sock"

    /// Called when a command notification is received.
    /// The string is the "description" field from the JSON message.
    var onMessage: ((String) -> Void)?

    private var serverFd: Int32 = -1
    private var listenerSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "ax.lock.socket", qos: .userInteractive)

    /// Start listening for connections.
    func start() {
        // Remove any stale socket file
        unlink(SocketListener.socketPath)

        // Create socket
        serverFd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFd >= 0 else {
            writeError("Failed to create socket: \(errno)")
            return
        }

        // Bind
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        SocketListener.socketPath.withCString { ptr in
            _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { dest in
                strcpy(dest, ptr)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverFd, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult >= 0 else {
            writeError("Failed to bind socket: \(errno)")
            close(serverFd)
            serverFd = -1
            return
        }

        // Listen
        guard listen(serverFd, 5) >= 0 else {
            writeError("Failed to listen on socket: \(errno)")
            close(serverFd)
            serverFd = -1
            return
        }

        // Set non-blocking
        let flags = fcntl(serverFd, F_GETFL, 0)
        _ = fcntl(serverFd, F_SETFL, flags | O_NONBLOCK)

        // Create dispatch source for incoming connections
        let source = DispatchSource.makeReadSource(fileDescriptor: serverFd, queue: queue)
        source.setEventHandler { [weak self] in
            self?.acceptConnection()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.serverFd, fd >= 0 {
                close(fd)
            }
        }
        source.resume()
        listenerSource = source
    }

    /// Stop listening and clean up.
    func stop() {
        listenerSource?.cancel()
        listenerSource = nil

        if serverFd >= 0 {
            close(serverFd)
            serverFd = -1
        }

        unlink(SocketListener.socketPath)
    }

    // MARK: - Private

    private func acceptConnection() {
        var clientAddr = sockaddr_un()
        var addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

        let clientFd = withUnsafeMutablePointer(to: &clientAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                accept(serverFd, sockaddrPtr, &addrLen)
            }
        }

        guard clientFd >= 0 else { return }

        // Read message in background, then dispatch to main
        queue.async { [weak self] in
            self?.handleClient(clientFd)
        }
    }

    private func handleClient(_ fd: Int32) {
        defer { close(fd) }

        // Set client socket to blocking mode (inherited non-blocking from server)
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags & ~O_NONBLOCK)

        // Set read timeout
        var timeout = timeval(tv_sec: 0, tv_usec: 100_000)  // 100ms
        _ = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        // Read up to 4KB (plenty for JSON message)
        var buffer = [CChar](repeating: 0, count: 4096)
        let bytesRead = recv(fd, &buffer, buffer.count - 1, 0)

        guard bytesRead > 0 else { return }

        buffer[Int(bytesRead)] = 0
        let message = String(cString: buffer)

        // Parse JSON
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let description = json["description"] as? String else {
            return
        }

        // Dispatch to main thread for UI update
        DispatchQueue.main.async { [weak self] in
            self?.onMessage?(description)
        }
    }

    private func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
