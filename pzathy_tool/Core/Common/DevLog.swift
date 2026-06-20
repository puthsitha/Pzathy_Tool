//
//  DevLog.swift
//  pzathy_tool
//
//  Lightweight developer logging that makes two things easy to follow in the
//  Xcode console while building/maintaining the app:
//
//    1. The current page (view) — every screen logs when it appears/disappears
//       via the `.logPage("Name")` modifier.
//    2. API traffic — `URLSession.loggedData(for:)` logs each request, its
//       status code and how long it took.
//
//  Everything is gated behind DEBUG, so release builds stay completely silent
//  (no logging overhead, nothing leaked to device logs). It uses the unified
//  `os.Logger`, so entries are filterable in Console.app / Xcode by the
//  "Page" and "API" categories.
//

import Foundation
import os

enum DevLog {

    /// Master switch. On in DEBUG, off in release. Flip to `false` locally if
    /// you want to silence the logs temporarily.
    #if DEBUG
    static var isEnabled = true
    #else
    static var isEnabled = false
    #endif

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.pzathy.tool"
    private static let pageLog = Logger(subsystem: subsystem, category: "Page")
    private static let apiLog  = Logger(subsystem: subsystem, category: "API")

    // MARK: - Page tracking

    /// Logs which page is currently on screen, e.g. `📄 Home — appeared`.
    static func page(_ name: String, _ event: String = "appeared") {
        guard isEnabled else { return }
        pageLog.log("📄 \(name, privacy: .public) — \(event, privacy: .public)")
    }

    // MARK: - API tracking

    /// Logs an outgoing request, e.g. `➡️ GET https://…/streams/abc`.
    static func request(_ method: String, _ url: URL?) {
        guard isEnabled else { return }
        apiLog.log("➡️ \(method, privacy: .public) \(url?.absoluteString ?? "nil", privacy: .public)")
    }

    /// Logs a completed response with status code + elapsed time.
    static func response(_ method: String, _ url: URL?, status: Int, elapsed: TimeInterval) {
        guard isEnabled else { return }
        let ms = String(format: "%.0f", elapsed * 1000)
        let icon = (200..<300).contains(status) ? "✅" : "⚠️"
        apiLog.log("\(icon, privacy: .public) \(status) \(method, privacy: .public) \(url?.absoluteString ?? "nil", privacy: .public) (\(ms, privacy: .public) ms)")
    }

    /// Logs a failed request (network error, cancellation, decode failure…).
    static func failure(_ method: String, _ url: URL?, error: Error) {
        guard isEnabled else { return }
        apiLog.error("❌ \(method, privacy: .public) \(url?.absoluteString ?? "nil", privacy: .public) — \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - Page logging view modifier

import SwiftUI

extension View {
    /// Logs to the console when this page appears and disappears, so the
    /// "current page" is always visible while developing. No-op in release.
    ///
    ///     SettingsView()
    ///         .logPage("Settings")
    func logPage(_ name: String) -> some View {
        self
            .onAppear { DevLog.page(name, "appeared") }
            .onDisappear { DevLog.page(name, "disappeared") }
    }
}

// MARK: - API logging URLSession wrapper

extension URLSession {
    /// Drop-in replacement for `data(for:)` that logs the request, the response
    /// status + timing, and any failure. Behaves identically otherwise.
    func loggedData(for request: URLRequest) async throws -> (Data, URLResponse) {
        let method = request.httpMethod ?? "GET"
        DevLog.request(method, request.url)
        let start = Date()
        do {
            let (data, response) = try await data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            DevLog.response(method, request.url, status: status, elapsed: Date().timeIntervalSince(start))
            return (data, response)
        } catch {
            DevLog.failure(method, request.url, error: error)
            throw error
        }
    }
}
