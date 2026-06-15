//
//  AppColors.swift
//  pzathy_tool
//
//  Central color palette. Theme: natural, muted green with a calm dark mode.
//  All colors are dynamic (adapt to light / dark) so `system` theme works for free.
//

import SwiftUI
import UIKit

/// Helper that builds a UIColor resolving differently for light / dark appearance.
private func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { traits in
        traits.userInterfaceStyle == .dark ? dark : light
    }
}

private func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
    UIColor(red: r, green: g, blue: b, alpha: 1.0)
}

/// Semantic colors used across the app.
enum AppColor {

    /// Brand accent — a muted sage / forest green (not too saturated).
    static let accent = Color(dynamicColor(
        light: rgb(0.412, 0.667, 0.553),   // #69AA8D-ish sage
        dark:  rgb(0.486, 0.717, 0.616)    // a touch brighter for dark surfaces
    ))

    /// A deeper forest green for emphasis / gradients.
    static let accentDeep = Color(dynamicColor(
        light: rgb(0.231, 0.420, 0.345),
        dark:  rgb(0.302, 0.490, 0.408)
    ))

    /// App background.
    static let background = Color(dynamicColor(
        light: rgb(0.961, 0.973, 0.965),   // off-white with faint green tint
        dark:  rgb(0.067, 0.086, 0.078)    // near-black with green undertone
    ))

    /// Card / grouped content background.
    static let surface = Color(dynamicColor(
        light: rgb(1.0, 1.0, 1.0),
        dark:  rgb(0.114, 0.137, 0.125)
    ))

    /// Slightly raised surface (e.g. player bar).
    static let surfaceElevated = Color(dynamicColor(
        light: rgb(0.965, 0.976, 0.969),
        dark:  rgb(0.149, 0.176, 0.161)
    ))

    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    static let separator = Color(UIColor.separator)
}
