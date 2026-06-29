//
//  PomodoroSettingsView.swift
//  pzathy_tool
//
//  Adjusts the Pomodoro durations, the long-break cadence and behaviour
//  toggles. Edits bind straight to the view model, which persists them.
//

import SwiftUI

struct PomodoroSettingsView: View {
    @ObservedObject var vm: PomodoroTimerViewModel
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    stepperRow(title: loc.t(.focusLength),
                               value: $vm.settings.focusMinutes,
                               range: 1...90, unit: loc.t(.minutesShort))
                    stepperRow(title: loc.t(.shortBreakLength),
                               value: $vm.settings.shortBreakMinutes,
                               range: 1...30, unit: loc.t(.minutesShort))
                    stepperRow(title: loc.t(.longBreakLength),
                               value: $vm.settings.longBreakMinutes,
                               range: 1...60, unit: loc.t(.minutesShort))
                }

                Section {
                    stepperRow(title: loc.t(.roundsBeforeLongBreak),
                               value: $vm.settings.roundsBeforeLongBreak,
                               range: 1...12, unit: nil)
                }

                Section {
                    Toggle(loc.t(.autoStartNext), isOn: $vm.settings.autoStartNext)
                    Toggle(loc.t(.soundAndHaptics), isOn: $vm.settings.soundAndHaptics)
                }
            }
            .navigationTitle(loc.t(.timerSettings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.t(.done)) { dismiss() }
                }
            }
        }
    }

    private func stepperRow(title: String, value: Binding<Int>,
                            range: ClosedRange<Int>, unit: String?) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text(unit.map { "\(value.wrappedValue) \($0)" } ?? "\(value.wrappedValue)")
                    .foregroundColor(AppColor.secondaryText)
                    .monospacedDigit()
            }
        }
    }
}
