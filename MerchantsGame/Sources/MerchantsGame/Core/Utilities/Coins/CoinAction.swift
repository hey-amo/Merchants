// An operation that changes a coin balance.
// Owns the add and subtract actions supported by FR3.
// Does not contain default amounts or game-specific transaction reasons.

public enum CoinAction: Equatable, Sendable {
    case add(Int)
    case subtract(Int)
}
