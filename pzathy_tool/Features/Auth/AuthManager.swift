//
//  AuthManager.swift
//  pzathy_tool
//
//  Dummy authentication: 3 hard-coded demo users, session persisted locally.
//  No registration / password reset / profile editing (by design, for now).
//

import SwiftUI
import Combine

struct User: Identifiable, Codable, Equatable {
    let id: String
    let username: String
    let displayName: String
    let role: String          // shown on the profile header (e.g. "IT Officer")
    let avatarSymbol: String  // SF Symbol used as a placeholder avatar

    // Password is only used for the dummy login check; never persisted with the session.
    var password: String = ""
}

final class AuthManager: ObservableObject {
    private static let sessionKey = "auth.session.username"

    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }

    /// The three demo accounts. Passwords are intentionally simple.
    static let demoUsers: [User] = [
        User(id: "u1", username: "admin",   displayName: "Sitha Admin",
             role: "Administrator", avatarSymbol: "person.badge.key.fill", password: "admin123"),
        User(id: "u2", username: "officer", displayName: "Dara Officer",
             role: "Office Staff",  avatarSymbol: "briefcase.fill",        password: "officer123"),
        User(id: "u3", username: "it",      displayName: "Pisach IT",
             role: "IT Support",    avatarSymbol: "desktopcomputer",       password: "it123")
    ]

    init() {
        // Restore a previous session if one exists.
        if let saved = UserDefaults.standard.string(forKey: Self.sessionKey),
           let user = Self.demoUsers.first(where: { $0.username == saved }) {
            currentUser = Self.stripPassword(user)
        }
    }

    /// Returns true on success. Compares against the dummy users.
    @discardableResult
    func login(username: String, password: String) -> Bool {
        let name = username.trimmingCharacters(in: .whitespaces).lowercased()
        guard let match = Self.demoUsers.first(where: {
            $0.username.lowercased() == name && $0.password == password
        }) else {
            return false
        }
        currentUser = Self.stripPassword(match)
        UserDefaults.standard.set(match.username, forKey: Self.sessionKey)
        return true
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    private static func stripPassword(_ user: User) -> User {
        var u = user
        u.password = ""
        return u
    }
}
