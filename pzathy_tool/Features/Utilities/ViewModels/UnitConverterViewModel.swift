//
//  UnitConverterViewModel.swift
//  pzathy_tool
//
//  Drives the Unit Converter: tracks the selected category, the from/to units
//  and the input, and exposes a formatted result.
//

import Foundation
import Combine

@MainActor
final class UnitConverterViewModel: ObservableObject {
    @Published var category: UnitCategory {
        didSet {
            guard category != oldValue else { return }
            fromUnit = category.units[0]
            toUnit = category.units.count > 1 ? category.units[1] : category.units[0]
        }
    }
    @Published var fromUnit: UnitDef
    @Published var toUnit: UnitDef
    @Published var input: String = "1"

    init() {
        let first = UnitConverter.categories[0]
        self.category = first
        self.fromUnit = first.units[0]
        self.toUnit = first.units.count > 1 ? first.units[1] : first.units[0]
    }

    /// The numeric input, or nil when the field is empty / not a number.
    var inputValue: Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Accept both "." and "," as the decimal separator.
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    /// Converted result, or nil when the input isn't a valid number.
    var result: Double? {
        guard let value = inputValue else { return nil }
        return UnitConverter.convert(value, from: fromUnit, to: toUnit)
    }

    /// Result formatted for display ("—" when the input is invalid/empty).
    var resultText: String {
        guard let result else { return "—" }
        return Self.format(result)
    }

    func swap() {
        let tmp = fromUnit
        fromUnit = toUnit
        toUnit = tmp
    }

    /// Formats a value with up to 6 fraction digits, trimming noise.
    static func format(_ x: Double) -> String {
        NumberFormat.trimmed(x, maxFractionDigits: 6)
    }
}
