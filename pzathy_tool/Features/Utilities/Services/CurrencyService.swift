//
//  CurrencyService.swift
//  pzathy_tool
//
//  Fetches live exchange rates from the open, key-free ExchangeRate-API
//  endpoint (https://www.exchangerate-api.com/docs/free). Rates are returned
//  relative to USD.
//

import Foundation

enum CurrencyServiceError: Error {
    case badResponse
    case providerError
}

struct CurrencyService {
    /// Free, no-key endpoint returning USD-based rates for ~160 currencies.
    static let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!

    func fetchRates() async throws -> CurrencyRates {
        var request = URLRequest(url: Self.endpoint)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.loggedData(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw CurrencyServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(ERApiResponse.self, from: data)
        guard decoded.result == "success" else {
            throw CurrencyServiceError.providerError
        }
        return CurrencyRates(
            base: decoded.base_code,
            rates: decoded.rates,
            updated: decoded.time_last_update_utc,
            fetchedAt: Date()
        )
    }
}

/// Matches the ExchangeRate-API `/latest` JSON shape.
private struct ERApiResponse: Decodable {
    let result: String
    let base_code: String
    let time_last_update_utc: String?
    let rates: [String: Double]
}
