//
//  CurrencyPickerView.swift
//  pzathy_tool
//
//  A searchable list for picking a currency code, presented as a sheet.
//

import SwiftUI

struct CurrencyPickerView: View {
    let codes: [String]
    @Binding var selection: String
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationView {
            List(filtered, id: \.self) { code in
                Button {
                    selection = code
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(code).font(.body.weight(.semibold))
                            Text(CurrencyInfo.name(for: code))
                                .font(.caption).foregroundColor(AppColor.secondaryText)
                        }
                        Spacer()
                        if code == selection {
                            Image(systemName: "checkmark").foregroundColor(AppColor.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .foregroundColor(AppColor.primaryText)
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: loc.t(.search))
            .navigationTitle(loc.t(.selectCurrency))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t(.cancel)) { dismiss() }
                }
            }
        }
    }

    private var filtered: [String] {
        guard !search.isEmpty else { return codes }
        let q = search.lowercased()
        return codes.filter {
            $0.lowercased().contains(q) || CurrencyInfo.name(for: $0).lowercased().contains(q)
        }
    }
}
