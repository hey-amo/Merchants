//
//  PlayerProfileView.swift
//  Merchants
//
//  Created by Amarjit on 10/11/2026.
//

import SwiftUI

// A view/card showing a player's profile, tableau, etc
struct PlayerProfileView: View {
    let player: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            PlayerAvatarView(avatarIndex: player.avatarIndex, state: .onTurn)
                .frame(height: 96)
                .accessibilityHidden(true)
            HStack(spacing: 6) {
                Text(player.kindEmoji)
                    .accessibilityHidden(true)
                Text(player.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }
            CoinValueView(value: player.coins)
        }
    }
}

#Preview {
    PlayerProfileView( player: PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0))
}
