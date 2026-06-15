//
//  LoginView.swift
//  pzathy_tool
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var loc: LocalizationManager

    @State private var username = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.accentDeep.opacity(0.18), AppColor.background],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(spacing: 14) {
                        field(icon: "person", placeholder: loc.t(.username), text: $username, secure: false)
                        field(icon: "lock", placeholder: loc.t(.password), text: $password, secure: true)

                        if showError {
                            Text(loc.t(.invalidCredentials))
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: attemptLogin) {
                            Text(loc.t(.signIn))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(AppColor.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(username.isEmpty || password.isEmpty)
                        .opacity(username.isEmpty || password.isEmpty ? 0.6 : 1)
                    }
                    .padding(18)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 6)

                    demoAccounts
                }
                .padding(20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [AppColor.accent, AppColor.accentDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: AppColor.accent.opacity(0.4), radius: 12, y: 6)

            Text(loc.t(.loginTitle))
                .font(.title2).fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text(loc.t(.loginSubtitle))
                .font(.subheadline)
                .foregroundColor(AppColor.secondaryText)
        }
        .padding(.top, 24)
    }

    private func field(icon: String, placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppColor.secondaryText)
                .frame(width: 20)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var demoAccounts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.t(.demoAccounts).uppercased())
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(AppColor.secondaryText)

            ForEach(AuthManager.demoUsers) { user in
                Button {
                    username = user.username
                    password = user.password
                    showError = false
                } label: {
                    HStack {
                        Image(systemName: user.avatarSymbol)
                            .foregroundColor(AppColor.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(user.displayName).font(.subheadline).fontWeight(.medium)
                            Text("\(user.username) · \(user.role)")
                                .font(.caption).foregroundColor(AppColor.secondaryText)
                        }
                        Spacer()
                        Text(loc.t(.tapToFill))
                            .font(.caption2)
                            .foregroundColor(AppColor.accent)
                    }
                    .padding(12)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func attemptLogin() {
        let ok = auth.login(username: username, password: password)
        withAnimation { showError = !ok }
    }
}
