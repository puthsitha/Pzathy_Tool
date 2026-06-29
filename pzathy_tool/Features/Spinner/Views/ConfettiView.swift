//
//  ConfettiView.swift
//  pzathy_tool
//
//  A lightweight, self-contained confetti burst (no third-party deps). Bumping
//  `trigger` spawns a fresh set of pieces that fall and fade.
//

import SwiftUI

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xFraction: CGFloat
    let xDrift: CGFloat
    let color: Color
    let size: CGFloat
    let delay: Double
    let spin: Double
}

struct ConfettiView: View {
    /// Increment to fire a new burst.
    let trigger: Int

    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false

    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        AppColor.accent, AppColor.accentDeep
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(animate ? piece.spin : 0))
                        .position(
                            x: piece.xFraction * geo.size.width + (animate ? piece.xDrift : 0),
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(.easeOut(duration: 2.2).delay(piece.delay), value: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _ in burst() }
    }

    private func burst() {
        pieces = (0..<80).map { _ in
            ConfettiPiece(
                xFraction: CGFloat.random(in: 0...1),
                xDrift: CGFloat.random(in: -80...80),
                color: Self.colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 7...13),
                delay: Double.random(in: 0...0.35),
                spin: Double.random(in: 180...720)
            )
        }
        // Reset to the start position without animating, then animate the fall.
        animate = false
        DispatchQueue.main.async {
            withAnimation { animate = true }
        }
    }
}
