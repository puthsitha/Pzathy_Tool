//
//  AdsManager.swift
//  pzathy_tool
//
//  Ads scaffolding for the future. Everything is OFF by default and hidden,
//  so no ad UI shows today — but the integration points already exist.
//
//  When you're ready (e.g. Google AdMob), set `adsEnabled = true`, drop the SDK
//  in, and replace `AdBannerView`'s placeholder body with the real banner.
//

import SwiftUI

final class AdsManager: ObservableObject {
    /// Master switch. Keep false until ads are actually integrated & approved.
    @Published var adsEnabled: Bool = false

    /// When background playback is disabled the app could show/insert ads later.
    /// Exposed now so feature code can branch on it without future refactors.
    var shouldShowRewardedForBackground: Bool { adsEnabled }
}

/// Banner placeholder. Renders nothing while ads are disabled.
struct AdBannerView: View {
    @EnvironmentObject private var ads: AdsManager

    var body: some View {
        if ads.adsEnabled {
            // TODO: Replace with real banner (e.g. GADBannerView wrapper).
            Color.clear
                .frame(height: 50)
                .overlay(Text("Ad").font(.caption2).foregroundColor(AppColor.tertiaryText))
                .accessibilityHidden(true)
        } else {
            EmptyView()
        }
    }
}
