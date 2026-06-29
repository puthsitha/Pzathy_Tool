//
//  CurrencyModels.swift
//  pzathy_tool
//
//  Models for the Currency converter. Exchange rates are fetched relative to a
//  single base (USD) and cached for offline use.
//

import Foundation

/// A snapshot of exchange rates, all expressed relative to `base`.
struct CurrencyRates: Codable, Equatable {
    let base: String
    let rates: [String: Double]
    /// Human-readable "last updated" string from the provider, if any.
    let updated: String?
    /// When this snapshot was fetched on-device.
    let fetchedAt: Date

    func rate(_ code: String) -> Double? { rates[code] }
}

enum CurrencyInfo {
    /// Localized display name for a currency code (e.g. "US Dollar"), code as fallback.
    static func name(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// Common currencies used as a fallback list before any rates are loaded.
    static let fallbackCodes = [
        "USD", "EUR", "GBP", "JPY", "CNY", "KHR", "THB", "VND", "AUD", "CAD",
        "CHF", "HKD", "SGD", "INR", "KRW", "MYR", "PHP", "IDR", "NZD", "RUB",
        "BRL", "ZAR", "AED", "SAR"
    ]
}
