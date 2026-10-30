import SwiftUI

struct CubeSelectionScreen: View {
    @State private var session: GameSession
    let onStartGame: () -> Void

    init(session: GameSession, onStartGame: @escaping () -> Void) {
        _session = State(initialValue: session)
        self.onStartGame = onStartGame
    }

    var body: some View {
        let _ = session.revision

        VStack(spacing: 20) {
            if session.stage == .cubeDraft {
                Text("Player \(session.activePlayer?.playerId ?? 0), choose a cube")
                    .font(.title2.bold())

                Text("Each player drafts two cubes in snake order.")
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 16) {
                    ForEach(GoodsCube.allCases, id: \.self) { color in
                        let availableCount = session.availableCubeCount(for: color)
                        Button {
                            perform { try session.selectDraftCube(color) }
                        } label: {
                            VStack(spacing: 6) {
                                CubeView(cube: color, size: 64)
                                Text(color.description)
                                Text("Available: \(availableCount)")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(availableCount == 0)
                    }
                }

                playerDraftStatus
            } else {
                Text("Cubes selected")
                    .font(.title2.bold())
                Text("The game is ready. Start when everyone is ready.")
                    .foregroundStyle(.secondary)
            }

            Button("Start game", action: onStartGame)
                .buttonStyle(.borderedProminent)
                .disabled(!session.isDraftComplete)
        }
        .padding()
        .navigationTitle("Select cubes")
        .alert(
            "Unable to select cube",
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

    private var playerDraftStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(session.players, id: \.playerId) { player in
                HStack {
                    Text("Player \(player.playerId)")
                    Spacer()
                    Text(player.cubes.map(\.description).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            session.errorMessage = error.localizedDescription
            session.revision += 1
        }
    }
}
