//
//  SpinnerItem.swift
//  pzathy_tool
//
//  A single choice on the spinner wheel.
//

import Foundation

struct SpinnerItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}
