//
//  PlayerHUDView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// Show a single player in a hud collection showing their coins and avatar
struct PlayerHUDView: View {
    var body: some View {
        VStack {
            PlayerAvatarView()
            CoinValueView(value: 50)
        }
    }
}

#Preview {
    PlayerHUDView()
}
