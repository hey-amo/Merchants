// Validation errors raised while creating a game configuration.
// Owns the failure cases required by FR1 and their localized descriptions.
// Does not describe errors from setup operations or gameplay.

import Foundation

public enum GameSetupError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidPlayerCount
    case duplicatePlayerID
    case unknownFirstPlayer

    public var description: String {
        switch self {
        case .invalidPlayerCount:
            String(localized: "gameSetup.invalidPlayerCount", bundle: .module)
        case .duplicatePlayerID:
            String(localized: "gameSetup.duplicatePlayerID", bundle: .module)
        case .unknownFirstPlayer:
            String(localized: "gameSetup.unknownFirstPlayer", bundle: .module)
        }
    }
}
