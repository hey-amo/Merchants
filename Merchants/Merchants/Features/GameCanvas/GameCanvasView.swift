//
//  GameCanvasView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import MerchantsGame

// Display the main game canvas view

// Structure: Full size screen (iPhone portrait)
// Scrollview {
// - Sticky HUD bar [List players | notification bell | hamburger menu
//
// - (small spacing)
// - Current Phase: (label) (tiny) | Cards remaining label
// - Last game message section
//
// - Carousel section: {
// ---- Crates in supply
// ---- Marketplace cards (default)
// ---- Player 2 (quick overview)
// ---- Player 3 (quick overview: if in the game)
// ---- Player 4 (quick overview: if in the game)
// ---- General stats (if implemented)
// } // :endCarousel
//
// - Carousel section: {
// ---- Your ships section
// ---- Your special cards
// }
//
// - Your cards (hand of cards move left to right, selectable)
// Footer (not used yet)
// }


import SwiftUI

struct GameCanvasView: View {
    let players: [PlayerViewModel]
    let phaseName: String
    let cardsLeft: UInt32
    let message: String?
    @Bindable var carousel: CarouselController

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                statusRow

                messagePlaceholder

                GameCarouselView(controller: carousel)
                    .frame(height: 280)

                sectionTitle("Your ships")

                sectionTitle("Your cards")

                endTurnButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            StickyHUDView(players: players)
        }
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text(phaseName)
                .font(.headline)

            Spacer()

            Text("Cards left: \(cardsLeft)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var messagePlaceholder: some View {
        Text(message ?? "No messages yet")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var endTurnButton: some View {
        Button("End turn") {
            // TODO: Wire up end-turn logic
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Game canvas") {
    GameCanvasView(
        players: [
            PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0),
            PlayerViewModel(name: "Ada", coins: 85, isHuman: false, avatarIndex: 1),
            PlayerViewModel(name: "Byron", coins: 40, isHuman: false, avatarIndex: 2),
            PlayerViewModel(name: "Cleo", coins: 200, isHuman: false, avatarIndex: 3)
        ],
        phaseName: "Buy phase",
        cardsLeft: 30,
        message: "Ada bought the Harbour crate",
        carousel: CarouselController()
    )
}

// MARK: - Preview

#Preview("Game canvas") {
    GameCanvasView(
        players: [
            PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0),
            PlayerViewModel(name: "Ada", coins: 85, isHuman: false, avatarIndex: 1),
            PlayerViewModel(name: "Byron", coins: 40, isHuman: false, avatarIndex: 2),
            PlayerViewModel(name: "Cleo", coins: 200, isHuman: false, avatarIndex: 3)
        ],
        phaseName: "Buy phase",
        cardsLeft: 30,
        message: "Ada bought the Harbour crate",
        carousel: CarouselController()
    )
}
