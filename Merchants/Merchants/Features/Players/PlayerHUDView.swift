//
//  PlayerHUDView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// Show a single player in a hud collection showing their coins and avatar
// the avatar is clickable?
struct PlayerHUDView: View {
    let coinValue: Int
    let index: Int
    let state: PlayerAvatarView.State
        
    var body: some View {
        //VStack (alignment: .center, spacing: 8.0) {
        VStack {
            PlayerAvatarView(avatarIndex: index, state: state).frame(width:100)
            CoinValueView(value: 50)
        }
    }
}

#Preview {
    //PlayerHUDView()
    HStack(spacing: 24) {
        PlayerHUDView(coinValue: 50, index: 1, state: .onTurn)
        PlayerHUDView(coinValue: 100, index: 1, state: .idle)
    }
    .padding()
    .frame(height: 140)
}
