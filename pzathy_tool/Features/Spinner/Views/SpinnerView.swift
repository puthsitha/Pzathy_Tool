//
//  SpinnerView.swift
//  pzathy_tool
//
//  The Spinner tool: add choices, spin the wheel, and celebrate the winner with
//  confetti, haptics and a sound. Optionally drop the winner from the list.
//

import SwiftUI

struct SpinnerView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @StateObject private var vm = SpinnerViewModel()

    @State private var newItem = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    WheelView(items: vm.items, rotation: vm.rotation)
                        .frame(height: 320)
                        .padding(.top, 8)

                    spinButton
                    optionsCard
                    itemsCard
                }
                .padding(16)
            }
            .scrollDismissesKeyboardCompat()

            if let winner = vm.winner {
                winnerOverlay(winner)
            }

            ConfettiView(trigger: vm.celebrationTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .navigationTitle(loc.t(.spinner))
        .navigationBarTitleDisplayMode(.inline)
        .logPage("Spinner")
    }

    // MARK: - Spin button

    private var spinButton: some View {
        VStack(spacing: 8) {
            Button(action: { fieldFocused = false; vm.spin() }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(loc.t(.spin))
                }
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .background(vm.canSpin ? AppColor.accent : AppColor.accent.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!vm.canSpin)

            if vm.items.count < 2 {
                Text(loc.t(.spinNeedItems))
                    .font(.caption).foregroundColor(AppColor.secondaryText)
            }
        }
    }

    // MARK: - Options

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Toggle(loc.t(.removeAfterSpin), isOn: $vm.removeAfterSpin)
                .padding(.vertical, 6)
            Divider()
            Toggle(loc.t(.celebrationSound), isOn: $vm.soundEnabled)
                .padding(.vertical, 6)
        }
        .tint(AppColor.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Items editor

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.t(.itemsHeader))
                    .font(.headline)
                Spacer()
                Text("\(vm.items.count)")
                    .font(.subheadline).foregroundColor(AppColor.secondaryText)
                if !vm.items.isEmpty {
                    Button(role: .destructive) { vm.removeAll() } label: {
                        Text(loc.t(.clearAll)).font(.caption.weight(.semibold))
                    }
                }
            }

            HStack(spacing: 10) {
                TextField(loc.t(.addItem), text: $newItem)
                    .focused($fieldFocused)
                    .submitLabel(.done)
                    .onSubmit(addItem)
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .background(AppColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button(action: addItem) {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(canAdd ? AppColor.accent : AppColor.accent.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(!canAdd)
            }

            ForEach(vm.items) { item in
                HStack {
                    Text(item.text).foregroundColor(AppColor.primaryText)
                    Spacer()
                    Button { vm.remove(item) } label: {
                        Image(systemName: "trash")
                            .foregroundColor(AppColor.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var canAdd: Bool {
        !newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addItem() {
        guard canAdd else { return }
        vm.add(newItem)
        newItem = ""
    }

    // MARK: - Winner overlay

    private func winnerOverlay(_ winner: SpinnerItem) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { vm.dismissWinner() }

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColor.accentDeep)
                Text(loc.t(.winnerTitle).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppColor.secondaryText)
                Text(winner.text)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3).minimumScaleFactor(0.6)

                HStack(spacing: 12) {
                    Button(action: { vm.dismissWinner() }) {
                        Text(loc.t(.done))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(AppColor.surfaceElevated)
                            .foregroundColor(AppColor.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Button(action: { vm.dismissWinner(); vm.spin() }) {
                        Text(loc.t(.spinAgain))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(AppColor.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(28)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(36)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.winner)
    }
}

private extension View {
    /// `scrollDismissesKeyboard` is iOS 16+; no-op on iOS 15.
    @ViewBuilder
    func scrollDismissesKeyboardCompat() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}
