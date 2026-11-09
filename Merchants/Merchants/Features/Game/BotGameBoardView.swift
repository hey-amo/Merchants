import MerchantsGame
import SwiftUI

struct BotGameBoardView: View {
    let state: GameState
    let winners: [PlayerID]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if state.ending.status == .finished {
                Text("Game over")
                    .font(.title2)
                Text("Winner: \(winners.map(\.rawValue).joined(separator: ", "))")
            } else if state.turn == nil {
                Text("Cube draft")
                    .font(.title2)
            } else {
                Text("Game in progress")
                    .font(.title2)
            }

            Text("Cards remaining: \(state.deck.remaining)")
            Text("Marketplace")
                .font(.headline)
            Text(state.marketplace.visibleCards.map { String(describing: $0.good).capitalized }
                .joined(separator: ", "))

            Text("Players")
                .font(.headline)
            ForEach(state.configuration.playerIDs, id: \.self) { player in
                if let seat = state.configuration.playerIDs.firstIndex(of: player),
                   let balance = state.bank.standings[player] {
                    VStack(alignment: .leading) {
                        Text("\(player.rawValue): \(balance.available) coins")
                        Text("Ships: \(shipContents(at: seat))")
                            .font(.subheadline)
                    }
                } else {
                    Text("\(player.rawValue): player information unavailable")
                }
            }
        }
    }

    private func shipContents(at seat: Int) -> String {
        state.fleets[seat].ships.map { ship in
            let goods = ship.cubes.map { String(describing: $0.good).capitalized }
            return goods.isEmpty ? "Empty" : goods.joined(separator: " + ")
        }.joined(separator: ", ")
    }
}
