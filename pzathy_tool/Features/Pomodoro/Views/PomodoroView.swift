//
//  PomodoroView.swift
//  pzathy_tool
//
//  The Pomodoro Timer tool: a focus/break countdown with a progress ring,
//  start / pause / reset / skip controls, a round indicator and adjustable
//  settings.
//

import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @StateObject private var vm = PomodoroTimerViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            phasePicker
            Spacer(minLength: 8)
            timerRing
            Spacer(minLength: 8)
            roundDots
            controls
            statsRow
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(loc.t(.pomodoroTimer))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            PomodoroSettingsView(vm: vm)
        }
        .logPage("Pomodoro Timer")
    }

    // MARK: - Phase picker

    private var phasePicker: some View {
        HStack(spacing: 8) {
            ForEach(PomodoroPhase.allCases) { phase in
                let selected = vm.phase == phase
                Button { vm.select(phase) } label: {
                    Text(loc.t(phase.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? phaseColor.opacity(0.18) : AppColor.surface)
                        .foregroundColor(selected ? phaseColor : AppColor.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Timer ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(AppColor.separator.opacity(0.35), lineWidth: 16)
            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: vm.progress)

            VStack(spacing: 8) {
                Image(systemName: vm.phase.symbol)
                    .font(.title3)
                    .foregroundColor(phaseColor)
                Text(TimeFormat.mmss(vm.remaining))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(AppColor.primaryText)
                Text(loc.t(vm.phase.titleKey).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(phaseColor)
            }
        }
        .frame(width: 270, height: 270)
        .padding(.vertical, 8)
    }

    // MARK: - Round indicator

    private var roundDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(1, vm.settings.roundsBeforeLongBreak), id: \.self) { i in
                Circle()
                    .fill(i < vm.roundInCycle ? phaseColor : AppColor.separator.opacity(0.4))
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 40) {
            secondaryButton(systemName: "arrow.counterclockwise",
                            label: loc.t(.resetTimer),
                            action: vm.reset)

            Button(action: vm.toggle) {
                Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 84, height: 84)
                    .background(phaseColor)
                    .clipShape(Circle())
                    .shadow(color: phaseColor.opacity(0.35), radius: 10, y: 4)
            }
            .accessibilityLabel(vm.isRunning ? loc.t(.pauseTimer) : loc.t(.startTimer))

            secondaryButton(systemName: "forward.end.fill",
                            label: loc.t(.skip),
                            action: vm.skip)
        }
        .padding(.bottom, 24)
    }

    private func secondaryButton(systemName: String, label: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColor.primaryText)
                    .frame(width: 56, height: 56)
                    .background(AppColor.surface)
                    .clipShape(Circle())
                Text(label)
                    .font(.caption2)
                    .foregroundColor(AppColor.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(AppColor.accent)
            Text("\(loc.t(.sessionsCompleted)): \(vm.completedFocusSessions)")
                .font(.subheadline)
                .foregroundColor(AppColor.secondaryText)
        }
    }

    // MARK: - Helpers

    /// Accent tint for the current phase — sage for focus, deeper green for breaks.
    private var phaseColor: Color {
        vm.phase.isBreak ? AppColor.accentDeep : AppColor.accent
    }
}
