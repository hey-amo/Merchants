//
//  SingleShipView.swift
//  Merchants
//

import SwiftUI
import MerchantsGame

// Display a single ship with 0, 1 or 2 cargo crates.
// Each crate sits in a circular badge, side by side along the bottom-right of the ship.
// Crates are only tappable during certain game phases, so interaction can be locked.
struct SingleShipView: View {
    static let maxCargo = 2

    /// Crates on board, in order. Anything beyond `maxCargo` is ignored.
    var cargo: [GoodType] = []
    /// When false (default) crates are display-only and don't respond to taps.
    var isInteractive: Bool = false
    var onSelectCrate: (_ good: GoodType, _ slot: Int) -> Void = { _, _ in }

    // Tuning: ship width and crate badge diameter, in points.
    private let shipWidth: CGFloat = 150
    private let badgeSize: CGFloat = 50

    private var visibleCargo: [GoodType] { Array(cargo.prefix(Self.maxCargo)) }

    var body: some View {
        Image("ship-nobg")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: shipWidth)
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 4) {
                    ForEach(Array(visibleCargo.enumerated()), id: \.offset) { slot, good in
                        crateBadge(good, slot: slot)
                    }
                }
                .padding(4)
            }
    }

    @ViewBuilder
    private func crateBadge(_ good: GoodType, slot: Int) -> some View {
        let badge = SingleCrateView(resourceImage: good.crateImageName)
            .padding(badgeSize * 0.12)
            .frame(width: badgeSize, height: badgeSize)
            .background(Circle().fill(Color.black.opacity(0.35)))
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))

        if isInteractive {
            Button { onSelectCrate(good, slot) } label: { badge }
                .buttonStyle(.plain)
                .accessibilityLabel("\(good.displayName) crate")
                .accessibilityHint("Selects this crate")
        } else {
            badge
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(good.displayName) crate")
        }
    }
}

#Preview("Cargo states") {
    VStack {
        SingleShipView()
        SingleShipView(cargo: [.indigo])
        SingleShipView(cargo: [.spices, .tea], isInteractive: true)
    }
    .padding()
}
