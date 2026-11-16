// Validated inputs for creating a new game.
// Owns seating order, replay seed, first-player selection, and game rules.
// Does not build the game state or consume randomness beyond seed generation.

import Foundation

public struct GameConfiguration: Codable, Equatable, Sendable {
    public let playerIDs: [PlayerID]
    public let seed: UInt64
    public let firstPlayer: FirstPlayer
    public let rules: GameRules

    public init(
        playerIDs: [PlayerID],
        seed: UInt64,
        firstPlayer: FirstPlayer = .random,
        rules: GameRules = .standard
    ) throws(GameSetupError) {
        try Self.validate(playerIDs: playerIDs, firstPlayer: firstPlayer)
        self.init(
            validatedPlayerIDs: playerIDs,
            seed: seed,
            firstPlayer: firstPlayer,
            rules: rules
        )
    }

    public static func randomSeeded(
        playerIDs: [PlayerID],
        firstPlayer: FirstPlayer = .random,
        rules: GameRules = .standard
    ) throws(GameSetupError) -> Self {
        try validate(playerIDs: playerIDs, firstPlayer: firstPlayer)
        var generator = SystemRandomNumberGenerator()
        return Self(
            validatedPlayerIDs: playerIDs,
            seed: generator.next(),
            firstPlayer: firstPlayer,
            rules: rules
        )
    }

    private init(
        validatedPlayerIDs: [PlayerID],
        seed: UInt64,
        firstPlayer: FirstPlayer,
        rules: GameRules
    ) {
        self.playerIDs = validatedPlayerIDs
        self.seed = seed
        self.firstPlayer = firstPlayer
        self.rules = rules
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let playerIDs = try container.decode([PlayerID].self, forKey: .playerIDs)
        let seed = try container.decode(UInt64.self, forKey: .seed)
        let firstPlayer = try container.decode(FirstPlayer.self, forKey: .firstPlayer)
        let rules = try container.decode(GameRules.self, forKey: .rules)
        try self.init(
            playerIDs: playerIDs,
            seed: seed,
            firstPlayer: firstPlayer,
            rules: rules
        )
    }

    private static func validate(
        playerIDs: [PlayerID],
        firstPlayer: FirstPlayer
    ) throws(GameSetupError) {
        guard PlayerCount.range.contains(playerIDs.count) else {
            throw .invalidPlayerCount
        }
        guard Set(playerIDs).count == playerIDs.count else {
            throw .duplicatePlayerID
        }
        if case .fixed(let playerID) = firstPlayer,
           !playerIDs.contains(playerID) {
            throw .unknownFirstPlayer
        }
    }

    private enum CodingKeys: String, CodingKey {
        case playerIDs
        case seed
        case firstPlayer
        case rules
    }
}
