// Cross-owner failures found while validating a restored game state.
// Does not replace the errors owned by individual domain types.
import Foundation

public enum GameStateError: Error, Equatable, Sendable, LocalizedError {
    case invalidPlayerState
    case cardCountMismatch
    case cubeCountMismatch
    case handOverLimit
    case shipOverCapacity
    case shipNotFull
    case negativeBalance
    case invalidSpecialCardStock
    case invalidFleet
    case invalidTurnState

    public var errorDescription: String? { GameRestorationError.message }
}
