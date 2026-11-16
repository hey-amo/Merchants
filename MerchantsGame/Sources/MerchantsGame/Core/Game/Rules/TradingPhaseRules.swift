public enum TradingAction: Equatable, Sendable {
    case deliver([DeliveryPlacement])
    case draw
    case skip
}

public enum TradingOutcome: Equatable, Sendable {
    case delivered(GoodType)
    case drew(base: Int, officeExtras: Int, deckEmptied: Bool)
    case skipped
}

public enum TradingPhaseError: Error, Equatable, Sendable {
    case invalidPlayerState
}

public struct TradingState: Equatable, Sendable {
    public var turnFlow: TurnFlow
    public var hands: [Hand]
    public var tableaux: [Tableau]
    public var deck: DrawDeck
    public var marketplace: Marketplace
    public var rules: GameRules

    public init(
        turnFlow: TurnFlow, hands: [Hand], tableaux: [Tableau],
        deck: DrawDeck, marketplace: Marketplace, rules: GameRules = .standard
    ) {
        self.turnFlow = turnFlow
        self.hands = hands
        self.tableaux = tableaux
        self.deck = deck
        self.marketplace = marketplace
        self.rules = rules
    }
}

public struct TradingResult: Equatable, Sendable {
    public let state: TradingState
    public let outcome: TradingOutcome
}

public enum TradingPhaseRules {
    public static func apply(
        _ action: TradingAction, by seat: Int, to state: TradingState
    ) throws -> TradingResult {
        guard state.hands.count == state.turnFlow.order.count,
              state.tableaux.count == state.turnFlow.order.count,
              state.hands.indices.contains(seat) else {
            throw TradingPhaseError.invalidPlayerState
        }

        var next = state
        let effects = SpecialCardEffects(tableau: state.tableaux[seat], rules: state.rules)
        let limit = state.rules.handLimitBase + effects.handLimitBonus
        let room = try state.hands[seat].room(limit: limit)
        let flowAction: TurnFlow.TradingAction
        switch action {
        case .deliver: flowAction = .deliver
        case .draw: flowAction = .draw
        case .skip: flowAction = .skip
        }
        try next.turnFlow.completeTrading(
            by: seat, action: flowAction, deckCount: state.deck.remaining, handRoom: room
        )

        let outcome: TradingOutcome
        switch action {
        case .deliver(let placements):
            try next.marketplace.deliver(placements)
            // Marketplace validation ensures at least one card and a single good.
            guard let good = placements.first?.card.good else { throw MarketplaceError.emptyDelivery }
            _ = try next.hands[seat].remove(good: good, count: placements.count)
            outcome = .delivered(good)
        case .draw:
            let baseCount = min(2, next.deck.remaining)
            let baseCards = try next.deck.draw(baseCount)
            try next.hands[seat].add(baseCards, limit: limit)
            let remainingRoom = try next.hands[seat].room(limit: limit)
            let extraCount = min(effects.officeExtraDraws, remainingRoom, next.deck.remaining)
            if extraCount > 0 {
                let extraCards = try next.deck.draw(extraCount)
                try next.hands[seat].add(extraCards, limit: limit)
            }
            outcome = .drew(base: baseCount, officeExtras: extraCount, deckEmptied: next.deck.isEmpty)
        case .skip:
            outcome = .skipped
        }
        return TradingResult(state: next, outcome: outcome)
    }
}
