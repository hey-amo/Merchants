public struct GameSession: Sendable {
    private let store: GameStore

    public init(configuration: GameConfiguration) throws {
        store = GameStore(initialState: try GameState(configuration: configuration))
    }

    public init(restoring state: GameState) throws(GameStateError) {
        try GameInvariants.validate(state)
        store = GameStore(initialState: state)
    }

    /// Full host state, including hidden cards. Use playerView(for:) for players.
    public func snapshot() async -> GameState {
        await store.snapshot()
    }

    public func playerView(for player: PlayerID) async throws -> PlayerView {
        try await store.playerView(for: player)
    }

    public func legalActions(for player: PlayerID) async throws(EngineError) -> [GameAction] {
        try await store.legalActions(for: player)
    }

    public func send(_ action: GameAction, by player: PlayerID) async throws(ActionRejection) {
        try await store.send(action, by: player)
    }

    public func updates() async -> AsyncStream<GameUpdate> {
        await store.updates()
    }

    public func standings() async throws -> Standings {
        try await store.standings()
    }
}
