// Owns the live game state, serializes actions, and broadcasts successful updates.
// Rejected actions leave the state and all update streams unchanged.

import Foundation

public struct GameUpdate: Equatable, Sendable {
    public let newState: GameState
    public let events: [GameEvent]

    public init(newState: GameState, events: [GameEvent]) {
        self.newState = newState
        self.events = events
    }
}

public actor GameStore {
    private var state: GameState
    private var subscribers: [UUID: AsyncStream<GameUpdate>.Continuation] = [:]

    public init(initialState: GameState) {
        state = initialState
    }

    /// Full host state, including hidden cards. Use playerView(for:) for players.
    public func snapshot() -> GameState {
        state
    }

    public func playerView(for player: PlayerID) throws -> PlayerView {
        try state.playerView(for: player)
    }

    public func legalActions(for player: PlayerID) throws(EngineError) -> [GameAction] {
        try state.legalActions(for: player)
    }

    public func standings() throws -> Standings {
        try state.ending.standings(players: state.configuration.playerIDs, bank: state.bank)
    }

    public func send(_ action: GameAction, by player: PlayerID) throws(ActionRejection) {
        let (newState, events) = try GameEngine.apply(action, by: player, to: state)
        state = newState

        let update = GameUpdate(newState: newState, events: events)
        let gameEnded = newState.ending.status == .finished
        for continuation in subscribers.values {
            continuation.yield(update)
            if gameEnded {
                continuation.finish()
            }
        }
        if gameEnded {
            subscribers.removeAll()
        }
    }

    /// Host-only updates contain full state, including hidden cards.
    public func updates() -> AsyncStream<GameUpdate> {
        let (stream, continuation) = AsyncStream<GameUpdate>.makeStream()
        guard state.ending.status != .finished else {
            continuation.finish()
            return stream
        }

        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        subscribers[id] = continuation
        return stream
    }

    var activeSubscriberCount: Int {
        subscribers.count
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }
}
