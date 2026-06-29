//
//  CurrencyConverterView.swift
//  pzathy_tool
//
//  The Currency converter: enter an amount, pick two currencies and convert
//  using live (cached for offline) exchange rates.
//

import SwiftUI

struct CurrencyConverterView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = CurrencyConverterViewModel()

    @FocusState private var amountFocused: Bool
    private enum PickerTarget: Int, Identifiable {
        case from, to
        var id: Int { rawValue }
    }
    @State private var picking: PickerTarget?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                converterCard
                if let line = vm.rateLine {
                    rateInfo(line)
                }
                if !network.isConnected {
                    banner(icon: "wifi.slash", text: loc.t(.offlineBanner), tint: .orange)
                }
                if vm.errorMessage == "load" {
                    banner(icon: "exclamationmark.triangle", text: loc.t(.ratesError), tint: .red)
                }
            }
            .padding(16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { amountFocused = false }
        .navigationTitle(loc.t(.currency))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await vm.refresh(isConnected: network.isConnected) } } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(vm.isLoading)
            }
        }
        .sheet(item: $picking) { target in
            CurrencyPickerView(
                codes: vm.availableCodes,
                selection: target == .from ? $vm.fromCode : $vm.toCode
            )
        }
        .task { await vm.refresh(isConnected: network.isConnected) }
        .logPage("Currency Converter")
    }

    // MARK: - Converter

    private var converterCard: some View {
        VStack(spacing: 14) {
            currencyField(title: loc.t(.from), code: vm.fromCode, target: .from) {
                TextField("0", text: $vm.amount)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
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

            currencyField(title: loc.t(.to), code: vm.toCode, target: .to) {
                Text(vm.resultText)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColor.accentDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
        }
    }

    private func currencyField<Content: View>(
        title: String,
        code: String,
        target: PickerTarget,
        @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppColor.tertiaryText)
                Spacer()
                Button { picking = target } label: {
                    HStack(spacing: 4) {
                        Text(code).font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                    }
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppColor.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            value()
            Text(CurrencyInfo.name(for: code))
                .font(.caption).foregroundColor(AppColor.secondaryText)
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func rateInfo(_ line: String) -> some View {
        VStack(spacing: 4) {
            Text(line)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppColor.primaryText)
            if let updated = vm.lastUpdatedText {
                Text("\(loc.t(.lastUpdated)): \(updated)")
                    .font(.caption2).foregroundColor(AppColor.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func banner(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
            Spacer()
        }
        .font(.caption.weight(.medium))
        .foregroundColor(tint)
        .padding(.vertical, 8).padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
