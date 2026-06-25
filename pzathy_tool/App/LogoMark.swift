//
//  LogoMark.swift
//  pzathy_tool
//
//  A vector rendering of the Pzathy Tools mark — a neon hexagon with a crossed
//  wrench & screwdriver. Used as a graceful fallback on the splash screen until
//  the real "AppLogo" raster is added to the asset catalog, and anywhere the
//  brand mark is needed without a bitmap.
//

import SwiftUI

/// Blue → purple neon gradient matching the app logo.
enum BrandGradient {
    static let colors = [Color(red: 0.25, green: 0.50, blue: 1.0),
                         Color(red: 0.60, green: 0.30, blue: 0.95)]

    static var diagonal: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var horizontal: LinearGradient {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
}

/// A flat-top hexagon inscribed in its rect.
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to:    CGPoint(x: 0.25 * w, y: 0))
        p.addLine(to: CGPoint(x: 0.75 * w, y: 0))
        p.addLine(to: CGPoint(x: w,        y: 0.5 * h))
        p.addLine(to: CGPoint(x: 0.75 * w, y: h))
        p.addLine(to: CGPoint(x: 0.25 * w, y: h))
        p.addLine(to: CGPoint(x: 0,        y: 0.5 * h))
        p.closeSubpath()
        return p
    }
}

struct LogoMark: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .fill(Color.black)

                Hexagon()
                    .stroke(BrandGradient.diagonal,
                            style: StrokeStyle(lineWidth: side * 0.045, lineJoin: .round))
                    .shadow(color: BrandGradient.colors[0].opacity(0.8), radius: side * 0.04)
                    .shadow(color: BrandGradient.colors[1].opacity(0.6), radius: side * 0.06)
                    .padding(side * 0.16)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(BrandGradient.diagonal)
                    .shadow(color: BrandGradient.colors[0].opacity(0.7), radius: side * 0.03)
                    .padding(side * 0.32)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LogoMark().frame(width: 160, height: 160).padding().background(.black)
}
