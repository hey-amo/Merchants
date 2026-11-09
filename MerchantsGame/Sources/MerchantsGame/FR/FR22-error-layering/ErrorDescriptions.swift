import Foundation

private extension SpecialCardKind {
    var errorName: String {
        switch self {
        case .ship: String(localized: "Ship", bundle: .module)
        case .largeShip: String(localized: "Large Ship", bundle: .module)
        case .office: String(localized: "Office", bundle: .module)
        case .crane: String(localized: "Crane", bundle: .module)
        case .tradeAgreement: String(localized: "Trade Agreement", bundle: .module)
        case .customsHouse: String(localized: "Customs House", bundle: .module)
        }
    }
}

extension CoinError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .isNegativeNumber: String(localized: "A coin amount cannot be negative.", bundle: .module)
        case .insufficientFunds(let required, let available):
            String(localized: "Not enough coins: \(required) required, \(available) available.", bundle: .module)
        case .limitExceeded(let limit, let attempted):
            String(localized: "The balance of \(attempted) exceeds the limit of \(limit).", bundle: .module)
        case .overflow: String(localized: "The coin calculation is too large.", bundle: .module)
        }
    }
}

extension BankingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknownPlayer(let player):
            String(localized: "Player \(player.rawValue) has no bank account.", bundle: .module)
        case .coin(let error): error.description
        }
    }
}

extension DrawDeckError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty: String(localized: "The draw deck is empty.", bundle: .module)
        case .invalidCount: String(localized: "The number of cards to draw cannot be negative.", bundle: .module)
        }
    }
}

extension HandError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .limitExceeded(let limit, let attempted):
            String(localized: "A hand of \(attempted) cards exceeds the limit of \(limit).", bundle: .module)
        case .insufficientCards(let good, let required, let available):
            String(localized: "Not enough \(String(describing: good)) cards: \(required) required, \(available) available.", bundle: .module)
        case .invalidLimit(let limit):
            String(localized: "The hand limit \(limit) cannot be negative.", bundle: .module)
        case .invalidCount(let count):
            String(localized: "The card count \(count) cannot be negative.", bundle: .module)
        }
    }
}

extension CubeSupplyError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noneAvailable(let good):
            String(localized: "No \(String(describing: good)) cubes are available.", bundle: .module)
        case .supplyFull(let good):
            String(localized: "The supply of \(String(describing: good)) cubes is already full.", bundle: .module)
        case .invalidCount(let good, let count):
            String(localized: "The \(String(describing: good)) cube count \(count) is invalid.", bundle: .module)
        case .missingCount(let good):
            String(localized: "The supply is missing the \(String(describing: good)) cube count.", bundle: .module)
        }
    }
}

extension ShipError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .shipNotFound: String(localized: "The selected ship does not exist.", bundle: .module)
        case .cubeIndexOutOfRange: String(localized: "The selected cube is not on the ship.", bundle: .module)
        case .capacityExceeded: String(localized: "The ship cannot carry more cubes.", bundle: .module)
        case .sameGood: String(localized: "Choose a cube of a different colour.", bundle: .module)
        }
    }
}

extension MarketplaceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidSlotCount: String(localized: "The marketplace must have six non-empty slots.", bundle: .module)
        case .emptyDelivery: String(localized: "Deliver at least one card.", bundle: .module)
        case .mixedGoods: String(localized: "All delivered cards must be the same colour.", bundle: .module)
        case .duplicateSlot: String(localized: "Each delivered card must use a different marketplace slot.", bundle: .module)
        case .slotOutOfRange: String(localized: "The selected marketplace slot does not exist.", bundle: .module)
        case .tooManyCards: String(localized: "No more than six cards can be delivered at once.", bundle: .module)
        }
    }
}

extension SpecialCardError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .outOfStock(let kind):
            String(localized: "The \(kind.errorName) card is out of stock.", bundle: .module)
        case .ownershipLimitReached(let kind):
            String(localized: "The ownership limit for \(kind.errorName) has been reached.", bundle: .module)
        case .invalidCatalog: String(localized: "The special-card catalogue is invalid.", bundle: .module)
        case .invalidPlayerCount: String(localized: "The special-card stock requires two to four players.", bundle: .module)
        case .invalidStock: String(localized: "The special-card stock is invalid.", bundle: .module)
        case .invalidTableau: String(localized: "The player's special-card collection is invalid.", bundle: .module)
        case .invalidRules: String(localized: "The configured game rules are invalid.", bundle: .module)
        case .overflow: String(localized: "The special-card calculation is too large.", bundle: .module)
        }
    }
}

extension TurnFlowError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidSeating: String(localized: "The player seating order is invalid.", bundle: .module)
        case .invalidDraftPosition: String(localized: "The draft position is invalid.", bundle: .module)
        case .notYourTurn: String(localized: "It is not this player's turn.", bundle: .module)
        case .wrongPhase: String(localized: "This action is not available in the current phase.", bundle: .module)
        case .phaseAlreadyCompleted: String(localized: "This phase has already been completed.", bundle: .module)
        case .baseActionRequired: String(localized: "Choose a planning action before ending the phase.", bundle: .module)
        case .baseActionAlreadyTaken: String(localized: "A planning action has already been taken this turn.", bundle: .module)
        case .shipAlreadyExchangedThisPhase: String(localized: "This ship has already exchanged a cube this phase.", bundle: .module)
        case .shipAddedThisTurn: String(localized: "A newly bought ship cannot exchange a cube this turn.", bundle: .module)
        case .noExtraExchangeAvailable: String(localized: "No extra cube exchange is available.", bundle: .module)
        case .cannotDrawMustDeliver: String(localized: "Cards cannot be drawn now; deliver cards if possible.", bundle: .module)
        case .skipOnlyWhenDeckEmpty: String(localized: "Trading can only be skipped when the deck is empty.", bundle: .module)
        case .gameNotStarted: String(localized: "The game has not started.", bundle: .module)
        case .gameFinished: String(localized: "The game has already finished.", bundle: .module)
        case .invalidProgress: String(localized: "The turn progress is invalid.", bundle: .module)
        }
    }
}

extension CubeDraftError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDraftingSeat: String(localized: "It is not this player's turn to draft a cube.", bundle: .module)
        case .shipNotEmpty: String(localized: "Choose an empty ship for the draft cube.", bundle: .module)
        case .draftComplete: String(localized: "The cube draft is already complete.", bundle: .module)
        case .draftNotComplete: String(localized: "Complete the cube draft before starting turns.", bundle: .module)
        case .ship(let error): error.description
        case .supply(let error): error.description
        case .invalidState: String(localized: "The cube draft state is invalid.", bundle: .module)
        }
    }
}

extension PlanningError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidState: String(localized: "The planning state is invalid.", bundle: .module)
        case .unknownPlayer: String(localized: "The player is not in this game.", bundle: .module)
        case .invalidShipLoad: String(localized: "Choose the required number of cubes for the purchase.", bundle: .module)
        case .turn(let error): error.description
        case .banking(let error): error.description
        case .supply(let error): error.description
        case .ship(let error): error.description
        case .specialCard(let error): error.description
        }
    }
}

extension TradingPhaseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPlayerState: String(localized: "The trading player state is invalid.", bundle: .module)
        }
    }
}

extension DeliveryScoringError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPlayers: String(localized: "The players or fleets supplied for scoring are invalid.", bundle: .module)
        case .overflow: String(localized: "The delivery score is too large.", bundle: .module)
        case .specialCards(let error): error.description
        }
    }
}

extension GameEndingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .gameNotOver: String(localized: "The game has not finished yet.", bundle: .module)
        case .alreadyTriggered: String(localized: "The final round has already begun.", bundle: .module)
        case .alreadyEnded: String(localized: "The game has already ended.", bundle: .module)
        case .invalidSeat: String(localized: "The selected seat is invalid.", bundle: .module)
        case .unexpectedSeat: String(localized: "This seat cannot complete a turn now.", bundle: .module)
        case .invalidPlayers: String(localized: "The players supplied for the standings are invalid.", bundle: .module)
        }
    }
}

extension GameStateError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPlayerState: String(localized: "The saved player state is inconsistent.", bundle: .module)
        case .cardCountMismatch: String(localized: "The saved game has an incorrect number of cards.", bundle: .module)
        case .cubeCountMismatch: String(localized: "The saved game has an incorrect number of cubes.", bundle: .module)
        case .handOverLimit: String(localized: "A saved hand exceeds its card limit.", bundle: .module)
        case .shipOverCapacity: String(localized: "A saved ship exceeds its cube capacity.", bundle: .module)
        case .shipNotFull: String(localized: "A saved ship has no cubes.", bundle: .module)
        case .negativeBalance: String(localized: "A saved coin balance is invalid.", bundle: .module)
        case .invalidSpecialCardStock: String(localized: "The saved special-card stock is inconsistent.", bundle: .module)
        case .invalidFleet: String(localized: "A saved fleet does not match its special cards.", bundle: .module)
        case .invalidTurnState: String(localized: "The saved turn or game-ending state is invalid.", bundle: .module)
        }
    }
}
