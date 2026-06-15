//
//  Thumbnail.swift
//  pzathy_tool
//
//  Reusable artwork view with a graceful placeholder.
//

import SwiftUI

struct Thumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = 10

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            case .empty:
                placeholder.overlay(ProgressView())
            @unknown default:
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [AppColor.accent.opacity(0.4), AppColor.accentDeep.opacity(0.4)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
