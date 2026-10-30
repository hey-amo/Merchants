import SwiftUI

struct GameHandView: View {
    let player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hand (\(player.hand.count)/\(GameConstants.maxHandSize))")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(Array(player.hand.enumerated()), id: \.offset) { _, color in
                    VStack(spacing: 2) {
                        CubeView(cube: color, size: 38)
                        Text(color.description)
                            .font(.caption2)
                    }
                }
            }
        }
    }
}
