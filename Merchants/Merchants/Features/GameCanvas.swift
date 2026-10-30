import SwiftUI

struct GameCanvas: View {
    @State private var session: GameSession
    let onPause: () -> Void
    let onGameOver: () -> Void

    init(
        session: GameSession,
        onPause: @escaping () -> Void,
        onGameOver: @escaping () -> Void
    ) {
        _session = State(initialValue: session)
        self.onPause = onPause
        self.onGameOver = onGameOver
    }

    var body: some View {
        let _ = session.revision

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GameHeaderView(
                    players: session.players,
                    activePlayerID: session.activePlayer?.playerId
                )

                HStack {
                    Text("Marketplace")
                        .font(.title2.bold())
                    Spacer()
                    Text("Draw pile: \(session.game.drawPile.count)")
                        .foregroundStyle(.secondary)
                }

                if session.stage != .phase2 {
                    GameMarketplaceView(session: session)
                }

                if let player = session.activePlayer {
                    Text("Player \(player.playerId) · \(player.coins) coins")
                        .font(.headline)
                }

                switch session.stage {
                case .cubeDraft:
                    Text("Finish selecting cubes before starting the game.")
                case .phase1:
                    GamePhaseOneView(session: session)
                case .phase2:
                    GamePhaseTwoView(session: session, onGameOver: onGameOver)
                case .finished:
                    Text("Game over")
                }
            }
            .padding()
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Pause", action: onPause)
            }
        }
        .alert(
            "Unable to complete action",
            isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
}
