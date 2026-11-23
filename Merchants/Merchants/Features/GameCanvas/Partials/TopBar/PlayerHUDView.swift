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
            
            ZStack {
                PlayerAvatarView(avatarIndex: player.avatarIndex, state: .onTurn)
                    .frame(height: 60)
                    .accessibilityHidden(true)
                
                // BOT/AI
                Text(player.kindEmoji)
                    .accessibilityHidden(true)
            }
                        
            // Cards held (Count)
            HStack {
                Image("icon-cards-mini")
                    .resizable().frame(width:35, height:35)
                Text("\(player.cardCount)")
            }
        
            CoinValueView(value: player.coins)
        }
    }
}

#Preview {
    PlayerHUDView( player: PlayerViewModel(name: "You", coins: 120, cardCount: 3, isHuman: true, avatarIndex: 0))
}
