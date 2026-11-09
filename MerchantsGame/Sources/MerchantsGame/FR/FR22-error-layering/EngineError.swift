import Foundation

public enum EngineError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    case coins(CoinError)
    case banking(BankingError)
    case drawDeck(DrawDeckError)
    case hand(HandError)
    case cubeSupply(CubeSupplyError)
    case ships(ShipError)
    case marketplace(MarketplaceError)
    case specialCards(SpecialCardError)
    case turnFlow(TurnFlowError)
    case setup(GameSetupError)
    case draft(CubeDraftError)
    case planning(PlanningError)
    case trading(TradingPhaseError)
    case deliveryScoring(DeliveryScoringError)
    case gameEnding(GameEndingError)
    case state(GameStateError)
    case unknownPlayer
    case invalidAction
    case unexpected(String)

    public init(_ error: CoinError) { self = .coins(error) }
    public init(_ error: BankingError) { self = .banking(error) }
    public init(_ error: DrawDeckError) { self = .drawDeck(error) }
    public init(_ error: HandError) { self = .hand(error) }
    public init(_ error: CubeSupplyError) { self = .cubeSupply(error) }
    public init(_ error: ShipError) { self = .ships(error) }
    public init(_ error: MarketplaceError) { self = .marketplace(error) }
    public init(_ error: SpecialCardError) { self = .specialCards(error) }
    public init(_ error: TurnFlowError) { self = .turnFlow(error) }
    public init(_ error: GameSetupError) { self = .setup(error) }
    public init(_ error: CubeDraftError) { self = .draft(error) }
    public init(_ error: TradingPhaseError) { self = .trading(error) }
    public init(_ error: DeliveryScoringError) { self = .deliveryScoring(error) }
    public init(_ error: GameEndingError) { self = .gameEnding(error) }
    public init(_ error: GameStateError) { self = .state(error) }
    public init(_ error: PlanningError) {
        switch error {
        case .turn(let cause): self = .turnFlow(cause)
        case .banking(let cause): self = .banking(cause)
        case .supply(let cause): self = .cubeSupply(cause)
        case .ship(let cause): self = .ships(cause)
        case .specialCard(let cause): self = .specialCards(cause)
        case .unknownPlayer: self = .unknownPlayer
        case .invalidState, .invalidShipLoad: self = .planning(error)
        }
    }

    public var description: String {
        switch self {
        case .coins(let error): "coins: \(error)"
        case .banking(let error): "banking: \(error)"
        case .drawDeck(let error): "drawDeck: \(error)"
        case .hand(let error): "hand: \(error)"
        case .cubeSupply(let error): "cubeSupply: \(error)"
        case .ships(let error): "ships: \(error)"
        case .marketplace(let error): "marketplace: \(error)"
        case .specialCards(let error): "specialCards: \(error)"
        case .turnFlow(let error): "turnFlow: \(error)"
        case .setup(let error): "setup: \(error)"
        case .draft(let error): "draft: \(error)"
        case .planning(let error): "planning: \(error)"
        case .trading(let error): "trading: \(error)"
        case .deliveryScoring(let error): "deliveryScoring: \(error)"
        case .gameEnding(let error): "gameEnding: \(error)"
        case .state(let error): "state: \(error)"
        case .unknownPlayer: String(localized: "The player is not in this game.", bundle: .module)
        case .invalidAction: String(localized: "This action is not available now.", bundle: .module)
        case .unexpected(let detail):
            String(localized: "An unexpected error occurred: \(detail)", bundle: .module)
        }
    }

    public var errorDescription: String? {
        if case .state(let error) = self { return error.errorDescription }
        return String(localized: "Game error -- \(description)", bundle: .module)
    }
}
