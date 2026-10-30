//
//  WinnerScreenView.swift
//  Merchants
//
//  Created by Amarjit on 02/07/2026.
//

import SwiftUI

// Replace player names (1,2,3,4,5) with Avatars
// redesign the screen

struct WinnerScreenView: View {
    private let players: [Player]
    private let onPlayAgain: () -> Void

    init(
        players: [Player],
        onPlayAgain: @escaping () -> Void = {},
        useSamplePlayers: Bool = false
    ) {
        self.players = useSamplePlayers ? Self.samplePlayers : players
        self.onPlayAgain = onPlayAgain
    }

    private static let samplePlayers = [
        Player(playerId: 1, coins: 10),
        Player(playerId: 2, coins: 14),
        Player(playerId: 3, coins: 3),
        Player(playerId: 4, coins: 7),
        Player(playerId: 5, coins: 1)
    ]
    
    var sortedPlayers: [Player] {
        players.sorted { $0.coins > $1.coins }
    }

    var winners: [Player] {
        guard let highestScore = sortedPlayers.first?.coins else { return [] }
        return sortedPlayers.filter { $0.coins == highestScore }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 24)
                Image(systemName: "trophy.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.yellow)

                Text(winnerTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if winners.count > 1 {
                    HStack(spacing: 12) {
                        ForEach(winners, id: \.playerId) { winner in
                            Text(playerName(winner))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .cornerRadius(8)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(sortedPlayers, id: \.playerId) { player in
                        HStack {
                            Text(playerName(player))
                                .font(.body)
                                .fontWeight(isWinner(player) ? .bold : .regular)
                            Spacer()
                            Text("\(player.coins)")
                                .font(.body)
                                .fontWeight(isWinner(player) ? .bold : .regular)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)

                Spacer(minLength: 24)

                Button(action: onPlayAgain) {
                    Text("Play again")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 400)
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(Color(.systemTeal).opacity(0.10).ignoresSafeArea())
    }

    private var winnerTitle: String {
        switch winners.count {
        case 0:
            "No players"
        case 1:
            "\(playerName(winners[0])) is the Winner"
        default:
            "It's a Tie!"
        }
    }

    private func playerName(_ player: Player) -> String {
        "Player \(player.playerId)"
    }

    private func isWinner(_ player: Player) -> Bool {
        winners.contains { $0.playerId == player.playerId }
    }
}

#Preview {
    WinnerScreenView(players: [], useSamplePlayers: true)
}
