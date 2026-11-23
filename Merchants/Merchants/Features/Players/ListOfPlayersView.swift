//
//  ListOfPlayersView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// List of all players in the game, in a lazy horizontal scrollable way
// clickable, reports to log clicked player: X
// Fits narrow screens
// the clicking of players can be disabled for interactions

struct ListOfPlayersView: View {
    var body: some View {
        
        // for each player in the game
        CaptainAvatarImg(name: "captains", count: 5, index: 0).frame(height: 60)
    }
}

#Preview {
    ListOfPlayersView()
}
