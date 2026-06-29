//
//  UnitConverterModels.swift
//  pzathy_tool
//
//  Models for the Unit Converter tool. Every unit is described relative to its
//  category's base unit by an affine transform (`base = value * scale + offset`),
//  which covers both purely multiplicative units (length, mass…) and offset
//  units (temperature) with the same code path.
//

import Foundation

/// A single unit within a category.
struct UnitDef: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let symbol: String
    /// Multiplier toward the base unit.
    let scale: Double
    /// Additive offset toward the base unit (non-zero only for temperature).
    let offset: Double

    init(id: String, name: String, symbol: String, scale: Double, offset: Double = 0) {
        self.id = id; self.name = name; self.symbol = symbol
        self.scale = scale; self.offset = offset
    }
}

/// A group of inter-convertible units (e.g. Length, Mass…).
struct UnitCategory: Identifiable, Equatable {
    let id: String
    let nameKey: LKey
    let symbol: String
    let units: [UnitDef]

    static func == (lhs: UnitCategory, rhs: UnitCategory) -> Bool { lhs.id == rhs.id }
}

enum UnitConverter {

    /// Converts a value from one unit to another within the same category.
    static func convert(_ value: Double, from: UnitDef, to: UnitDef) -> Double {
        let base = value * from.scale + from.offset
        return (base - to.offset) / to.scale
    }

    static let categories: [UnitCategory] = [
        UnitCategory(id: "length", nameKey: .unitLength, symbol: "ruler", units: [
            UnitDef(id: "mm", name: "Millimeter", symbol: "mm", scale: 0.001),
            UnitDef(id: "cm", name: "Centimeter", symbol: "cm", scale: 0.01),
            UnitDef(id: "m",  name: "Meter",      symbol: "m",  scale: 1),
            UnitDef(id: "km", name: "Kilometer",  symbol: "km", scale: 1000),
            UnitDef(id: "in", name: "Inch",       symbol: "in", scale: 0.0254),
            UnitDef(id: "ft", name: "Foot",       symbol: "ft", scale: 0.3048),
            UnitDef(id: "yd", name: "Yard",       symbol: "yd", scale: 0.9144),
            UnitDef(id: "mi", name: "Mile",       symbol: "mi", scale: 1609.344)
        ]),
        UnitCategory(id: "mass", nameKey: .unitMass, symbol: "scalemass", units: [
            UnitDef(id: "mg", name: "Milligram", symbol: "mg", scale: 0.000001),
            UnitDef(id: "g",  name: "Gram",      symbol: "g",  scale: 0.001),
            UnitDef(id: "kg", name: "Kilogram",  symbol: "kg", scale: 1),
            UnitDef(id: "t",  name: "Tonne",     symbol: "t",  scale: 1000),
            UnitDef(id: "oz", name: "Ounce",     symbol: "oz", scale: 0.0283495),
            UnitDef(id: "lb", name: "Pound",     symbol: "lb", scale: 0.453592),
            UnitDef(id: "st", name: "Stone",     symbol: "st", scale: 6.35029)
        ]),
        UnitCategory(id: "temperature", nameKey: .unitTemperature, symbol: "thermometer.medium", units: [
            UnitDef(id: "c", name: "Celsius",    symbol: "°C", scale: 1,       offset: 0),
            UnitDef(id: "f", name: "Fahrenheit", symbol: "°F", scale: 5.0/9.0, offset: -160.0/9.0),
            UnitDef(id: "k", name: "Kelvin",     symbol: "K",  scale: 1,       offset: -273.15)
        ]),
        UnitCategory(id: "volume", nameKey: .unitVolume, symbol: "drop", units: [
            UnitDef(id: "ml",   name: "Milliliter",   symbol: "ml",  scale: 0.001),
            UnitDef(id: "l",    name: "Liter",        symbol: "L",   scale: 1),
            UnitDef(id: "m3",   name: "Cubic meter",  symbol: "m³",  scale: 1000),
            UnitDef(id: "tsp",  name: "Teaspoon",     symbol: "tsp", scale: 0.00492892),
            UnitDef(id: "tbsp", name: "Tablespoon",   symbol: "tbsp", scale: 0.0147868),
            UnitDef(id: "cup",  name: "Cup",          symbol: "cup", scale: 0.24),
            UnitDef(id: "pt",   name: "Pint (US)",    symbol: "pt",  scale: 0.473176),
            UnitDef(id: "gal",  name: "Gallon (US)",  symbol: "gal", scale: 3.78541)
        ]),
        UnitCategory(id: "speed", nameKey: .unitSpeed, symbol: "speedometer", units: [
            UnitDef(id: "mps",  name: "Meter/second",    symbol: "m/s",  scale: 1),
            UnitDef(id: "kmh",  name: "Kilometer/hour",  symbol: "km/h", scale: 0.277778),
            UnitDef(id: "mph",  name: "Mile/hour",       symbol: "mph",  scale: 0.44704),
            UnitDef(id: "kn",   name: "Knot",            symbol: "kn",   scale: 0.514444),
            UnitDef(id: "ftps", name: "Foot/second",     symbol: "ft/s", scale: 0.3048)
        ]),
        UnitCategory(id: "area", nameKey: .unitArea, symbol: "square.split.bottomrightquarter", units: [
            UnitDef(id: "m2",  name: "Square meter",     symbol: "m²",  scale: 1),
            UnitDef(id: "km2", name: "Square kilometer", symbol: "km²", scale: 1000000),
            UnitDef(id: "ft2", name: "Square foot",      symbol: "ft²", scale: 0.092903),
            UnitDef(id: "mi2", name: "Square mile",      symbol: "mi²", scale: 2589988.11),
            UnitDef(id: "ac",  name: "Acre",             symbol: "ac",  scale: 4046.86),
            UnitDef(id: "ha",  name: "Hectare",          symbol: "ha",  scale: 10000)
        ])
    ]
}
