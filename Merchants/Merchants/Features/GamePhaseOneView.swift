import SwiftUI

struct GamePhaseOneView: View {
    let session: GameSession

    @State private var selectedExchangeCube: Int?
    @State private var selectedExchangeColor: GoodsCube?
    @State private var selectedShipColor: GoodsCube?

    var body: some View {
        let _ = session.revision

        if let player = session.activePlayer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Phase 1 — Purchase")
                    .font(.title3.bold())

                if session.dockerExchangeAvailable {
                    Text("Use a Docker exchange (\(session.dockerExchangesRemaining) remaining), or finish Phase 1.")
                        .foregroundStyle(.secondary)
                    cubeExchangeContent(for: player)
                    Button("Finish Phase 1") {
                        perform { try session.finishPhase1() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Exchange one cube, buy one special card, or pass.")
                        .foregroundStyle(.secondary)
                    cubeExchangeContent(for: player)
                    Divider()
                    specialCardContent(for: player)

                    Button("Pass Phase 1") {
                        perform { try session.passPhase1() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func cubeExchangeContent(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exchange a cube")
                .font(.headline)

            ForEach(Array(player.cubes.enumerated()), id: \.offset) { index, color in
                Button {
                    selectedExchangeCube = index
                } label: {
                    Label(
                        "Ship \(index + 1): \(color.description)",
                        systemImage: selectedExchangeCube == index ? "checkmark.circle.fill" : "circle"
                    )
                }
                .buttonStyle(.bordered)
            }

            if let selectedExchangeCube {
                Text("Exchange for")
                    .font(.subheadline.bold())
                GameGoodsPickerView(
                    session: session,
                    selection: $selectedExchangeColor,
                    excluding: player.cubes.indices.contains(selectedExchangeCube)
                        ? player.cubes[selectedExchangeCube]
                        : nil
                )

                Button("Exchange cube") {
                    guard let selectedExchangeColor else { return }
                    perform {
                        try session.exchangeCube(at: selectedExchangeCube, for: selectedExchangeColor)
                        resetSelections()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedExchangeColor == nil)
            }
        }
    }

    private func specialCardContent(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buy a special card")
                .font(.headline)

            ForEach(session.availableSpecialCards, id: \.name) { card in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(card.name) · \(card.cost) coins")
                    Text(card.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if card.name == "Ship" {
                        GameGoodsPickerView(session: session, selection: $selectedShipColor)
                    }

                    Button("Buy \(card.name)") {
                        perform {
                            try session.buySpecialCard(
                                named: card.name,
                                shipCube: card.name == "Ship" ? selectedShipColor : nil
                            )
                            resetSelections()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        player.coins < card.cost ||
                        (card.name == "Ship" && selectedShipColor == nil)
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            session.errorMessage = error.localizedDescription
            session.revision += 1
        }
    }

    private func resetSelections() {
        selectedExchangeCube = nil
        selectedExchangeColor = nil
        selectedShipColor = nil
    }
}
