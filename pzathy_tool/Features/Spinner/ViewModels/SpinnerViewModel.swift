//
//  SpinnerViewModel.swift
//  pzathy_tool
//
//  Drives the Spinner wheel: manages the list of choices, the spin animation
//  state, the winner, and the celebration. The winner is chosen up front and
//  the target rotation is computed to land that slice under the pointer, so the
//  result always matches the visual — no floating-point rounding surprises.
//

import SwiftUI
import Combine
import AudioToolbox
import UIKit

@MainActor
final class SpinnerViewModel: ObservableObject {
    private static let itemsKey  = "spinner.items"
    private static let removeKey = "spinner.removeAfterSpin"
    private static let soundKey  = "spinner.soundEnabled"

    @Published private(set) var items: [SpinnerItem]
    @Published var removeAfterSpin: Bool {
        didSet { UserDefaults.standard.set(removeAfterSpin, forKey: Self.removeKey) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Self.soundKey) }
    }

    /// Current wheel rotation, in degrees (accumulates across spins).
    @Published var rotation: Double = 0
    @Published private(set) var isSpinning = false
    /// Set when a spin finishes; drives the winner card.
    @Published var winner: SpinnerItem?
    /// Bumped each time a spin finishes, to trigger a confetti burst.
    @Published private(set) var celebrationTrigger = 0

    /// Length of the spin animation, in seconds.
    let spinDuration: Double = 4.0

    init() {
        self.items = Self.loadItems()
        self.removeAfterSpin = UserDefaults.standard.bool(forKey: Self.removeKey)
        // Default the celebration sound ON unless the user has turned it off.
        if UserDefaults.standard.object(forKey: Self.soundKey) == nil {
            self.soundEnabled = true
        } else {
            self.soundEnabled = UserDefaults.standard.bool(forKey: Self.soundKey)
        }
    }

    var canSpin: Bool { items.count >= 2 && !isSpinning }

    // MARK: - List editing

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(SpinnerItem(text: trimmed))
        persistItems()
    }

    func remove(_ item: SpinnerItem) {
        items.removeAll { $0.id == item.id }
        persistItems()
    }

    func removeAtOffsets(_ offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persistItems()
    }

    func removeAll() {
        items.removeAll()
        persistItems()
    }

    // MARK: - Spin

    func spin() {
        guard canSpin else { return }
        isSpinning = true
        winner = nil

        let n = items.count
        let step = 360.0 / Double(n)
        let winnerIndex = Int.random(in: 0..<n)

        // Rotation (mod 360) that lands slice `winnerIndex`'s center at the top
        // pointer. Slices are laid out clockwise from the top.
        let targetMod = (360 - (Double(winnerIndex) * step + step / 2))
            .truncatingRemainder(dividingBy: 360)
        let currentMod = rotation.truncatingRemainder(dividingBy: 360)
        var delta = targetMod - currentMod
        if delta < 0 { delta += 360 }

        let fullTurns = 5.0
        let target = rotation + fullTurns * 360 + delta

        withAnimation(.timingCurve(0.33, 1, 0.68, 1, duration: spinDuration)) {
            rotation = target
        }

        let winnerItem = items[winnerIndex]
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) { [weak self] in
            self?.finishSpin(with: winnerItem)
        }
    }

    private func finishSpin(with item: SpinnerItem) {
        isSpinning = false
        winner = item
        celebrationTrigger += 1
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if soundEnabled {
            AudioServicesPlaySystemSound(1025)
        }
    }

    /// Dismisses the winner card; removes the winner first if the option is on.
    func dismissWinner() {
        if removeAfterSpin, let winner {
            remove(winner)
        }
        winner = nil
    }

    // MARK: - Persistence

    private func persistItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.itemsKey)
        }
    }

    private static func loadItems() -> [SpinnerItem] {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let decoded = try? JSONDecoder().decode([SpinnerItem].self, from: data)
        else {
            // First launch: seed a few example choices so the wheel isn't empty.
            return ["Yes", "No", "Maybe", "Ask again"].map { SpinnerItem(text: $0) }
        }
        return decoded
    }
}
