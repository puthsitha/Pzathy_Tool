//
//  CurrencyConverterViewModel.swift
//  pzathy_tool
//
//  Drives the Currency converter: holds the amount, the from/to codes and the
//  fetched rates, persists the last successful snapshot for offline use, and
//  exposes a formatted result.
//

import Foundation
import Combine

@MainActor
final class CurrencyConverterViewModel: ObservableObject {
    private static let cacheKey = "currency.rates.cache"
    private static let fromKey  = "currency.from"
    private static let toKey    = "currency.to"

    @Published var amount: String = "1"
    @Published var fromCode: String { didSet { persistSelection() } }
    @Published var toCode: String { didSet { persistSelection() } }
    @Published private(set) var rates: CurrencyRates?
    @Published private(set) var isLoading = false
    /// Localization key string for the current error, or nil. ("offline" / "load")
    @Published var errorMessage: String?

    private let service = CurrencyService()

    init() {
        self.fromCode = UserDefaults.standard.string(forKey: Self.fromKey) ?? "USD"
        self.toCode   = UserDefaults.standard.string(forKey: Self.toKey) ?? "EUR"
        self.rates    = Self.loadCache()
    }

    // MARK: - Derived state

    /// Codes available for selection — from the loaded rates, or a fallback list.
    var availableCodes: [String] {
        if let rates, !rates.rates.isEmpty {
            return rates.rates.keys.sorted()
        }
        return CurrencyInfo.fallbackCodes
    }

    var amountValue: Double? {
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    /// Converted result, or nil when input/rates are unavailable.
    var result: Double? {
        guard let amountValue, let rates,
              let from = rates.rate(fromCode), from > 0,
              let to = rates.rate(toCode) else { return nil }
        // All rates are relative to the same base, so cross-rate = to / from.
        return amountValue * (to / from)
    }

    var resultText: String {
        guard let result else { return "—" }
        return NumberFormat.trimmed(result, maxFractionDigits: 4, minFractionDigits: 2)
    }

    /// One unit of `fromCode` expressed in `toCode` (e.g. "1 USD = 4,100 KHR").
    var rateLine: String? {
        guard let rates,
              let from = rates.rate(fromCode), from > 0,
              let to = rates.rate(toCode) else { return nil }
        let perUnit = NumberFormat.trimmed(to / from, maxFractionDigits: 4, minFractionDigits: 2)
        return "1 \(fromCode) = \(perUnit) \(toCode)"
    }

    var lastUpdatedText: String? { rates?.updated }

    func swap() {
        let tmp = fromCode
        fromCode = toCode
        toCode = tmp
    }

    // MARK: - Networking

    func refresh(isConnected: Bool) async {
        guard isConnected else {
            if rates == nil { errorMessage = "offline" }
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await service.fetchRates()
            rates = fetched
            Self.saveCache(fetched)
        } catch {
            // Keep any cached rates usable; only surface an error if we have none.
            if rates == nil { errorMessage = "load" }
        }
    }

    // MARK: - Persistence

    private func persistSelection() {
        UserDefaults.standard.set(fromCode, forKey: Self.fromKey)
        UserDefaults.standard.set(toCode, forKey: Self.toKey)
    }

    private static func saveCache(_ rates: CurrencyRates) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private static func loadCache() -> CurrencyRates? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(CurrencyRates.self, from: data)
    }
}
