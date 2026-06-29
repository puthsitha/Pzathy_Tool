//
//  UnitConverterView.swift
//  pzathy_tool
//
//  The Unit Converter tool: pick a category, enter a value and convert between
//  two units with a tap-to-swap layout.
//

import SwiftUI

struct UnitConverterView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @StateObject private var vm = UnitConverterViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                categoryGrid
                converterCard
            }
            .padding(16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { inputFocused = false }
        .navigationTitle(loc.t(.unitConverter))
        .navigationBarTitleDisplayMode(.inline)
        .logPage("Unit Converter")
    }

    // MARK: - Category selector

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            ForEach(UnitConverter.categories) { category in
                let selected = vm.category == category
                Button { vm.category = category } label: {
                    VStack(spacing: 6) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 18))
                        Text(loc.t(category.nameKey))
                            .font(.caption.weight(.medium))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selected ? AppColor.accent.opacity(0.18) : AppColor.surface)
                    .foregroundColor(selected ? AppColor.accent : AppColor.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Converter

    private var converterCard: some View {
        VStack(spacing: 14) {
            // From
            unitField(title: loc.t(.from), selection: $vm.fromUnit) {
                TextField("0", text: $vm.input)
                    .keyboardType(.decimalPad)
                    .focused($inputFocused)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColor.primaryText)
            }

            Button(action: vm.swap) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }

            // To
            unitField(title: loc.t(.to), selection: $vm.toUnit) {
                Text(vm.resultText)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColor.accentDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
        }
    }

    private func unitField<Content: View>(
        title: String,
        selection: Binding<UnitDef>,
        @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppColor.tertiaryText)
                Spacer()
                Menu {
                    Picker("", selection: selection) {
                        ForEach(vm.category.units) { unit in
                            Text("\(unit.name) (\(unit.symbol))").tag(unit)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selection.wrappedValue.symbol)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                    }
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppColor.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            value()
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
