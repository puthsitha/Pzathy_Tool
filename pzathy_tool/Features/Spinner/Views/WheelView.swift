//
//  WheelView.swift
//  pzathy_tool
//
//  The spinning wheel itself: coloured pie slices with radial labels, a fixed
//  top pointer and a centre hub. Layout is in "degrees clockwise from the top",
//  matching the winner math in SpinnerViewModel.
//

import SwiftUI

/// A pie slice between two angles (SwiftUI angles: 0° = right, clockwise).
struct Sector: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// A downward-pointing triangle for the pointer.
struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WheelView: View {
    let items: [SpinnerItem]
    let rotation: Double

    /// Vibrant, evenly distributed palette for the slices.
    private static let palette: [Color] = [
        Color(red: 0.90, green: 0.49, blue: 0.36),
        Color(red: 0.36, green: 0.67, blue: 0.55),
        Color(red: 0.95, green: 0.74, blue: 0.33),
        Color(red: 0.40, green: 0.55, blue: 0.78),
        Color(red: 0.74, green: 0.47, blue: 0.69),
        Color(red: 0.45, green: 0.74, blue: 0.45),
        Color(red: 0.93, green: 0.58, blue: 0.55),
        Color(red: 0.36, green: 0.62, blue: 0.71)
    ]

    private func color(_ i: Int) -> Color {
        // Avoid the first and last slice sharing a colour when count is odd.
        Self.palette[i % Self.palette.count]
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2
            let step = items.isEmpty ? 360 : 360.0 / Double(items.count)

            ZStack {
                // Rotating wheel (slices + labels)
                ZStack {
                    ForEach(items.indices, id: \.self) { i in
                        Sector(
                            startAngle: .degrees(-90 + Double(i) * step),
                            endAngle: .degrees(-90 + Double(i + 1) * step)
                        )
                        .fill(color(i))
                    }

                    ForEach(items.indices, id: \.self) { i in
                        label(for: items[i], index: i, step: step, radius: radius)
                    }
                }
                .frame(width: side, height: side)
                .rotationEffect(.degrees(rotation))

                // Centre hub
                Circle()
                    .fill(AppColor.surface)
                    .frame(width: side * 0.16, height: side * 0.16)
                    .overlay(Circle().stroke(AppColor.accentDeep, lineWidth: 3))
                    .shadow(color: .black.opacity(0.15), radius: 3)

                // Fixed pointer at the top, pointing down into the wheel
                DownTriangle()
                    .fill(AppColor.accentDeep)
                    .frame(width: 28, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .position(x: side / 2, y: 2)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
        }
    }

    private func label(for item: SpinnerItem, index i: Int,
                       step: Double, radius: CGFloat) -> some View {
        let centerDeg = -90 + Double(i) * step + step / 2
        // Flip text on the left half so it never appears upside down.
        let norm = (centerDeg.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        let textAngle = (norm > 90 && norm < 270) ? centerDeg + 180 : centerDeg
        let rad = centerDeg * .pi / 180

        return Text(item.text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: radius * 0.66)
            .multilineTextAlignment(.center)
            .rotationEffect(.degrees(textAngle))
            .position(
                x: radius + cos(rad) * radius * 0.55,
                y: radius + sin(rad) * radius * 0.55
            )
    }
}
