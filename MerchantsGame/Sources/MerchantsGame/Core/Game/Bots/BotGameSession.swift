import Foundation

/// A successfully applied bot action and its resulting host state.
public struct BotGameStep: Sendable {
    public let player: PlayerID
    public let action: GameAction
    public let message: String
    public let state: GameState
}

public enum BotGameSessionError: Error, Equatable, Sendable, LocalizedError {
    case stepInProgress
    case noAction(PlayerID)

    public var errorDescription: String? {
        switch self {
        case .stepInProgress:
            return "A bot action is already in progress."
        case .noAction(let player):
            return "No action could be selected for \(player.rawValue)."
        }
    }
}

/// Drives one private game session using bots for every player.
public actor BotGameSession {
    private let session: GameSession
    private let strategist: AIStrategist
    private let logger: @Sendable (String) -> Void
    private var stepping = false

    public init(
        configuration: GameConfiguration,
        personality: StrategistPersonality = .aggressive,
        logger: @escaping @Sendable (String) -> Void = { print($0) }
    ) throws {
        session = try GameSession(configuration: configuration)
        strategist = AIStrategist(personality: personality, logger: { _ in })
        self.logger = logger
    }

    /// Returns host state for display; bot decisions use only the active player's view.
    public func snapshot() async -> GameState {
        await session.snapshot()
    }

    /// Applies one bot action, or returns nil once the game has finished.
    public func step() async throws -> BotGameStep? {
        guard !stepping else { throw BotGameSessionError.stepInProgress }
        stepping = true
        defer { stepping = false }
        try Task.checkCancellation()

        let state = await session.snapshot()
        guard state.ending.status != .finished else { return nil }
        let seat: Int
        if let turn = state.turn {
            seat = turn.currentSeat
        } else {
            seat = try state.draft.nextSeat()
        }
        let player = state.configuration.playerIDs[seat]
        let actions = try await session.legalActions(for: player)
        let action: GameAction
        let message: String
        if state.turn == nil {
            guard let choice = actions.first else { throw BotGameSessionError.noAction(player) }
            action = choice
            message = "Draft: \(player.rawValue) selected \(choice)."
        } else {
            let view = try await session.playerView(for: player)
            let observation = try StrategistObservation(
                playerView: view,
                playerOrder: state.configuration.playerIDs,
                rules: state.configuration.rules
            )
            guard let decision = strategist.decide(for: observation, legalActions: actions) else {
                throw BotGameSessionError.noAction(player)
            }
            action = decision.action
            message = "\(player.rawValue): \(decision.message)"
        }

        try Task.checkCancellation()
        try await session.send(action, by: player)
        let updated = await session.snapshot()
        logger(message)
        return BotGameStep(player: player, action: action, message: message, state: updated)
    }
}
