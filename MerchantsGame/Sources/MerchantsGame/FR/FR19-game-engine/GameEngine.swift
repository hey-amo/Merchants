public struct ActionRejection: Error, Equatable, Sendable, CustomStringConvertible {
    public let error: EngineError
    public let action: GameAction
    public let player: PlayerID
    public var description: String { "player \(player.rawValue), action \(action): \(error)" }
}

public enum GameEngine {
    public static func apply(
        _ action: GameAction, by player: PlayerID, to state: GameState
    ) throws(ActionRejection) -> (GameState, [GameEvent]) {
        do {
            return try applyInternal(action, by: player, to: state)
        } catch {
            let mapped: EngineError
            switch error {
            case let error as EngineError: mapped = error
            case let error as CubeDraftError: mapped = .draft(error)
            case let error as PlanningError:
                switch error {
                case .turn(let cause): mapped = .turnFlow(cause)
                case .banking(let cause): mapped = .banking(cause)
                case .supply(let cause): mapped = .cubeSupply(cause)
                case .ship(let cause): mapped = .ships(cause)
                case .specialCard(let cause): mapped = .specialCards(cause)
                case .unknownPlayer: mapped = .unknownPlayer
                case .invalidState, .invalidShipLoad: mapped = .planning(error)
                }
            case let error as TradingPhaseError: mapped = .trading(error)
            case let error as DeliveryScoringError: mapped = .deliveryScoring(error)
            case let error as GameEndingError: mapped = .gameEnding(error)
            case let error as TurnFlowError: mapped = .turnFlow(error)
            case let error as BankingError: mapped = .banking(error)
            case let error as HandError: mapped = .hand(error)
            case let error as MarketplaceError: mapped = .marketplace(error)
            case let error as DrawDeckError: mapped = .drawDeck(error)
            default: mapped = .unexpected(String(describing: error))
            }
            throw ActionRejection(error: mapped, action: action, player: player)
        }
    }

    private static func applyInternal(
        _ action: GameAction, by player: PlayerID, to state: GameState
    ) throws -> (GameState, [GameEvent]) {
        try state.ending.requireActive()
        guard let seat = state.configuration.playerIDs.firstIndex(of: player) else { throw EngineError.unknownPlayer }
        var next = state
        var events: [GameEvent] = []
        if case .draftCube(let good, let ship) = action {
            guard next.turn == nil else { throw EngineError.invalidAction }
            try next.draft.pick(by: seat, good: good, ship: ship)
            next.fleets = next.draft.fleets
            next.supply = next.draft.supply
            if next.draft.isComplete { next.turn = try next.draft.startTurns() }
            return (next, [.cubeDrafted(player: player, good: good, ship: ship)])
        }
        guard let turn = next.turn else { throw EngineError.invalidAction }
        let planning: PlanningAction?
        switch action {
        case .exchangeCube(let ship, let index, let good): planning = .exchange(ship: ship, cubeIndex: index, good: good)
        case .buySpecialCard(let kind, let goods): planning = .buy(kind, loadCubes: goods)
        case .passPlanning: planning = .pass
        case .endPlanning: planning = .endPlanning
        default: planning = nil
        }
        if let planning {
            let context = try PlanningState(players: state.configuration.playerIDs, rules: state.configuration.rules,
                                            turn: turn, bank: state.bank, supply: state.supply, fleets: state.fleets,
                                            stock: state.stock, tableaus: state.tableaux)
            let updated = try PlanningPhaseRules.apply(planning, by: player, to: context)
            next.turn = updated.turn
            next.bank = updated.bank
            next.supply = updated.supply
            next.fleets = updated.fleets
            next.stock = updated.stock
            next.tableaux = updated.tableaus
            switch action {
            case .exchangeCube(let ship, let index, let good):
                events.append(.cubeExchanged(player: player, ship: ship, cubeIndex: index, good: good))
            case .buySpecialCard(let kind, let goods):
                events.append(.specialCardBought(player: player, kind: kind, loadCubes: goods))
            case .passPlanning: events.append(.planningPassed(player: player))
            case .endPlanning: events.append(.planningEnded(player: player))
            default: throw EngineError.invalidAction
            }
            return (next, events)
        }
        let trading: TradingAction
        switch action {
        case .deliverCards(let placements): trading = .deliver(placements)
        case .drawCards: trading = .draw
        case .skipTrading: trading = .skip
        default: throw EngineError.invalidAction
        }
        let result = try TradingPhaseRules.apply(trading, by: seat, to: TradingState(
            turnFlow: turn, hands: state.hands, tableaux: state.tableaux,
            deck: state.deck, marketplace: state.marketplace, rules: state.configuration.rules
        ))
        next.turn = result.state.turnFlow
        next.hands = result.state.hands
        next.deck = result.state.deck
        next.marketplace = result.state.marketplace
        switch result.outcome {
        case .delivered(let good):
            guard case .deliverCards(let placements) = action else { throw EngineError.invalidAction }
            events.append(.cardsDelivered(player: player, placements: placements))
            let transactions = try DeliveryScoring.transactions(for: good, marketplace: next.marketplace,
                players: next.configuration.playerIDs, fleets: next.fleets, tableaux: next.tableaux, rules: next.configuration.rules)
            try next.bank.apply(transactions)
            events.append(contentsOf: transactions.map { .coinsEarned(player: $0.player, amount: $0.amount, reason: $0.reason) })
        case .drew(let base, let extras, let emptied):
            events.append(.cardsDrawn(player: player, count: base))
            if extras > 0 { events.append(.officeExtrasDrawn(player: player, count: extras)) }
            if emptied {
                try next.ending.deckEmptied(by: seat)
                events.append(.deckEmptied)
                if case .finalRound = next.ending.status {
                    events.append(.finalRoundBegan(endsAfter: next.configuration.playerIDs[turn.order.last]))
                }
            }
        case .skipped:
            events.append(.tradingSkipped(player: player))
        }
        if next.ending.status != .finished {
            try next.ending.turnCompleted(by: seat)
            events.append(.turnEnded(player: player))
        }
        if next.ending.status == .finished {
            try next.turn?.finish()
            let standings = try next.ending.standings(players: next.configuration.playerIDs, bank: next.bank)
            events.append(.gameEnded(winners: standings.winners))
        }
        return (next, events)
    }
}
