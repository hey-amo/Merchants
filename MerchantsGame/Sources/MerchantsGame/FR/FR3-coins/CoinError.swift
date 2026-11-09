// Errors raised while validating or changing a coin balance.
// Owns the failure cases required by FR3.
// Does not describe player, bank, or gameplay-specific failures.

public enum CoinError: Error, Equatable, Sendable {
    case isNegativeNumber
    case insufficientFunds(required: Int, available: Int)
    case limitExceeded(limit: Int, attempted: Int)
    case overflow
}
