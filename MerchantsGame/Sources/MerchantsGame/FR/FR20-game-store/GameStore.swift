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
