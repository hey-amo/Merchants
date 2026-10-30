//
//  PlayerSelectScreen.swift
//  Merchants
//
//  Created by Amarjit on 02/07/2026.
//

import SwiftUI

// Route: New game -> Select player -> Select cubes -> Play the game

// Fixes:
// I expect to pick my player avatar
// I expect to pick if its AI or not
// Game cannot start without at least 1 human player
// The layout of this screen is not very nice looking

struct PlayerSelectScreen: View {
    let onStartGame: (Int) -> Void
    @State private var playerCount = 2

    var body: some View {
        VStack(spacing: 24) {
            Image("ship-nobg").resizable().frame(width:80, height: 80)
            Text("Merchants").font(.largeTitle)
            Text("Choose players")
                .font(.largeTitle.bold())

            Stepper("Players: \(playerCount)", value: $playerCount, in: 2...5)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(0..<playerCount, id: \.self) { index in
                    PlayerAvatarView(avatar: AvatarResource.allCases[index])
                }
            }

            Button("Select cubes") {
                onStartGame(playerCount)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("New game")
    }
}

#Preview {
    PlayerSelectScreen(onStartGame: { _ in })
}
