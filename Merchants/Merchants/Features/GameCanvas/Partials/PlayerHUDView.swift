//
//  PlayerHUDView.swift
//  Merchants
//
//  Created by Amarjit on 10/11/2026.
//

import SwiftUI
import MerchantsGame

// A view/card showing a single player for the sticky in-game top bar
struct PlayerHUDView: View {
    let player: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            
            PlayerAvatarView(avatarIndex: player.avatarIndex, state: .onTurn)
                .frame(height: 60)
                .accessibilityHidden(true)
            HStack(spacing: 6) {
                Text(player.kindEmoji)
                    .accessibilityHidden(true)
                Text("🃏3")
                /*
                Text(player.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)*/
            }
            
            CoinValueView(value: player.coins)
        }
    }
}

#Preview {
    PlayerHUDView( player: PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0))
}
