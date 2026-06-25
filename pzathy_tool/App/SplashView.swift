//
//  SplashView.swift
//  pzathy_tool
//
//  Branded launch splash: the app logo + "Pzathy Tools" wordmark over the app
//  background. Shows the "AppLogo" asset when present, otherwise the vector
//  LogoMark, so it always looks right. Shown briefly on top of RootView.
//

import SwiftUI

struct SplashView: View {
    @State private var appear = false

    var body: some View {
        ZStack {
            // Solid dark backdrop matching the logo so there's no white flash.
            Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 24) {
                logo
                    .frame(width: 148, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .scaleEffect(appear ? 1 : 0.82)
                    .opacity(appear ? 1 : 0)

                Text("Pzathy Tools")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandGradient.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) { appear = true }
        }
    }

    /// Prefer the committed raster logo; fall back to the vector mark.
    @ViewBuilder
    private var logo: some View {
        if let ui = UIImage(named: "AppLogo") {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
        } else {
            LogoMark()
        }
    }
}

#Preview {
    SplashView()
}
