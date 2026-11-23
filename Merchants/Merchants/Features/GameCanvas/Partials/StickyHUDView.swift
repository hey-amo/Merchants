////
//  StickyHUDView.swift
//  Merchants
//
//  Created by AD on 23/11/2026.
//

import SwiftUI
import MerchantsGame
import OSLog

// The STICKY top bar view (iphone portrait size)
// - Sticky HUD view: [List players (scrollable) | notification bell | hamburger menu
// - Use: PlayerHUDView
// -- usage: ... PlayerHUDView( player: PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0))
// & show all 4 players in the preview

private let hudLogger = Logger(subsystem: "GameHUD", category: "StickyHUD")

struct StickyHUDView: View {
    let players: [PlayerViewModel]

    var body: some View {
        HStack(spacing: 12) {
            playerStrip

            iconButton(systemImage: "bell.fill", label: "Notifications") {
                hudLogger.info("Notifications button tapped")
            }

            iconButton(systemImage: "line.3.horizontal", label: "Menu") {
                hudLogger.info("Menu button tapped")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var playerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(players) { player in
                    PlayerHUDView(player: player)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func iconButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    StickyHUDView(players: [
        PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0),
        PlayerViewModel(name: "Ada", coins: 85, isHuman: false, avatarIndex: 1),
        PlayerViewModel(name: "Byron", coins: 40, isHuman: false, avatarIndex: 2),
        PlayerViewModel(name: "Cleo", coins: 200, isHuman: false, avatarIndex: 3)
    ])
    .frame(height: 170)
}
