import SwiftUI

struct GamePhaseTwoView: View {
    let session: GameSession
    let onGameOver: () -> Void

    @State private var selectedDeliveryColor: GoodsCube?
    @State private var selectedMarketplaceSlots = Set<Int>()

    var body: some View {
        let _ = session.revision

        Group {
            if let player = session.activePlayer {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Phase 2 — Deliver")
                        .font(.title3.bold())

                    GameMarketplaceView(
                        session: session,
                        selectedColor: selectedDeliveryColor,
                        selectedSlots: $selectedMarketplaceSlots,
                        isInteractive: !session.phase2ActionCompleted,
                        maxSelectionCount: selectedDeliveryCardCount(for: player)
                    )

                    if session.phase2ActionCompleted {
                        completedPhaseContent
                    } else {
                        deliverOrDrawContent(for: player)
                    }

                    Divider()
                    GameHandView(player: player)
                }
            }
        }
        .onChange(of: selectedDeliveryColor) { _, _ in
            selectedMarketplaceSlots.removeAll()
        }
    }

    @ViewBuilder
    private var completedPhaseContent: some View {
        if session.officeBonusAvailable && !session.officeBonusResolved {
            Text("Office bonus: draw one card, or skip it.")
                .foregroundStyle(.secondary)
            Button("Draw one Office card") {
                perform { try session.resolveOfficeBonus(drawCard: true) }
            }
            .buttonStyle(.bordered)
            Button("Skip Office card") {
                perform { try session.resolveOfficeBonus(drawCard: false) }
            }
            .buttonStyle(.bordered)
        } else {
            Text("Phase 2 complete. End the turn to continue.")
                .foregroundStyle(.secondary)
            Button("End turn") {
                perform {
                    try session.endTurn()
                    selectedDeliveryColor = nil
                    selectedMarketplaceSlots.removeAll()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func deliverOrDrawContent(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deliver matching cards to score, or draw two cards.")
                .foregroundStyle(.secondary)
            Text("Choose a card colour")
                .font(.headline)

            GameGoodsPickerView(
                session: session,
                selection: $selectedDeliveryColor,
                availableInHand: player.hand,
                requiresCubeSupply: false
            )

            if selectedDeliveryColor != nil {
                Text("Select a different marketplace space for each card.")
                    .font(.subheadline)
                Button("Deliver \(selectedMarketplaceSlots.count) card(s)") {
                    guard let selectedDeliveryColor else { return }
                    perform {
                        try session.deliverGoods(
                            color: selectedDeliveryColor,
                            to: selectedMarketplaceSlots.sorted()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedMarketplaceSlots.isEmpty)
            }

            Button("Draw two cards") {
                perform {
                    try session.drawTwoCards()
                    selectedDeliveryColor = nil
                    selectedMarketplaceSlots.removeAll()
                }
            }
            .buttonStyle(.bordered)
            .disabled(player.hand.count >= GameConstants.maxHandSize || session.game.drawPile.isEmpty)
        }
    }

    private func selectedDeliveryCardCount(for player: Player) -> Int {
        guard let selectedDeliveryColor else { return 0 }
        return player.hand.filter { $0 == selectedDeliveryColor }.count
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            if session.stage == .finished {
                onGameOver()
            }
        } catch {
            session.errorMessage = error.localizedDescription
            session.revision += 1
        }
    }
}
