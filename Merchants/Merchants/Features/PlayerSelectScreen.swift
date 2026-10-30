//
//  PlayerSelectScreen.swift
//  Merchants
//
//  Created by Amarjit on 02/07/2026.
//

import SwiftUI

// Route: New game -> Select player -> Select cubes -> Play the game

struct PlayerSelectScreen: View {
    let onStartGame: (Int) -> Void
    @State private var playerCount = 2

    var body: some View {
        VStack(spacing: 24) {
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
