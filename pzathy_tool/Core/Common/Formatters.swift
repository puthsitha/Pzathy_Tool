//
//  Formatters.swift
//  pzathy_tool
//

import Foundation

enum TimeFormat {
    /// Formats seconds as m:ss (or h:mm:ss for long items).
    static func mmss(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

enum NumberFormat {
    /// Formats a value with grouping and a trimmed number of fraction digits.
    /// Returns "—" for non-finite values.
    static func trimmed(_ value: Double,
                        maxFractionDigits: Int = 6,
                        minFractionDigits: Int = 0) -> String {
        guard value.isFinite else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = minFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
