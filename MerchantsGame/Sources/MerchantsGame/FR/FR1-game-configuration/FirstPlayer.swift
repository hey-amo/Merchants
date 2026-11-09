// First-player selection for a new game configuration.
// Owns the choice between seeded random selection and a fixed player.
// Does not resolve a random choice or manage turn order.

public enum FirstPlayer: Codable, Equatable, Sendable {
    case random
    case fixed(PlayerID)
}
