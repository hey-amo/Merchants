public enum StrategistPhase: Equatable, Sendable {
    case planning
    case additionalExchange(
        remaining: Int,
        shipsAlreadyExchanged: Set<Int>,
        shipsAddedThisTurn: Set<Int>
    )
    case trading
}

public enum StrategistPersonality: Equatable, Sendable {
    case conservative
    case aggressive
}

public enum StrategistInputError: Error, Equatable, Sendable {
    case invalidPlayerCount
    case duplicatePlayer
    case unknownPlayer
    case invalidMarketplace
    case invalidDeckCount
    case invalidBalance
    case catalogMismatch
    case invalidExtraExchangeCount
    case invalidPlayerOrder
    case inactiveTurn
    case notActivePlayer
    case invalidHand
}

public struct StrategistPlayerObservation: Equatable, Sendable {
    public let player: PlayerID
    public let coins: Int
    public let fleet: Fleet
    public let tableau: Tableau

    public init(player: PlayerID, coins: Int, fleet: Fleet, tableau: Tableau) {
        self.player = player
        self.coins = coins
        self.fleet = fleet
        self.tableau = tableau
    }
}

/// The strategist's small, immutable view of public game information and its own hand.
/// Opponent hands, deck order, and the rest of GameState are deliberately excluded.
public struct StrategistObservation: Equatable, Sendable {
    public let phase: StrategistPhase
    public let player: PlayerID
    public let ownPlayer: StrategistPlayerObservation
    public let hand: [GoodsCard]
    public let marketplace: [GoodsCard]
    public let players: [StrategistPlayerObservation]
    public let supply: CubeSupply
    public let stock: SpecialCardStock
    public let deckCount: Int
    public let rules: GameRules

    public init(
        phase: StrategistPhase,
        player: PlayerID,
        hand: [GoodsCard],
        marketplace: [GoodsCard],
        players: [StrategistPlayerObservation],
        supply: CubeSupply,
        stock: SpecialCardStock,
        deckCount: Int,
        rules: GameRules = .standard
    ) throws(StrategistInputError) {
        guard (2...4).contains(players.count) else { throw .invalidPlayerCount }
        guard Set(players.map(\.player)).count == players.count else { throw .duplicatePlayer }
        guard let ownPlayer = players.first(where: { $0.player == player }) else { throw .unknownPlayer }
        guard marketplace.count == Marketplace.slotCount else { throw .invalidMarketplace }
        guard deckCount >= 0 else { throw .invalidDeckCount }
        guard players.allSatisfy({ (0...Coins.maximumBalance).contains($0.coins) }) else {
            throw .invalidBalance
        }
        let handLimit = rules.handLimitBase + (ownPlayer.tableau.count(of: .customsHouse) > 0 ? 2 : 0)
        guard hand.count <= handLimit else { throw .invalidHand }
        guard stock.catalog == rules.specialCardCatalog else { throw .catalogMismatch }
        if case .additionalExchange(let remaining, _, _) = phase, remaining <= 0 {
            throw .invalidExtraExchangeCount
        }

        self.phase = phase
        self.player = player
        self.ownPlayer = ownPlayer
        self.hand = hand
        self.marketplace = marketplace
        self.players = players
        self.supply = supply
        self.stock = stock
        self.deckCount = deckCount
        self.rules = rules
    }

    /// Adapts the engine's player-safe projection without exposing GameState to the bot.
    public init(
        playerView: PlayerView,
        playerOrder: [PlayerID],
        rules: GameRules = .standard
    ) throws(StrategistInputError) {
        guard playerOrder.count == playerView.fleets.count,
              playerOrder.count == playerView.tableaux.count,
              Set(playerOrder).count == playerOrder.count else {
            throw .invalidPlayerOrder
        }
        guard let activeSeat = playerOrder.firstIndex(of: playerView.player) else {
            throw .unknownPlayer
        }
        guard let turn = playerView.turn else { throw .inactiveTurn }
        guard turn.order.count == playerOrder.count,
              Set(playerOrder) == Set(playerView.bank.standings.keys) else {
            throw .invalidPlayerOrder
        }
        guard turn.currentSeat == activeSeat else { throw .notActivePlayer }

        let phase: StrategistPhase
        switch turn.status {
        case .active(.trading):
            phase = .trading
        case .active(.planning(let progress)):
            let remaining = progress.extrasAllowed - progress.extrasUsed
            if progress.baseAction != .none, remaining > 0 {
                phase = .additionalExchange(
                    remaining: remaining,
                    shipsAlreadyExchanged: progress.shipsExchanged,
                    shipsAddedThisTurn: progress.shipsAddedThisTurn
                )
            } else {
                phase = .planning
            }
        case .notStarted, .finished:
            throw .inactiveTurn
        }

        var players: [StrategistPlayerObservation] = []
        for (seat, player) in playerOrder.enumerated() {
            guard let coins = playerView.bank.standings[player]?.available else {
                throw .unknownPlayer
            }
            players.append(
                StrategistPlayerObservation(
                    player: player,
                    coins: coins,
                    fleet: playerView.fleets[seat],
                    tableau: playerView.tableaux[seat]
                )
            )
        }

        try self.init(
            phase: phase,
            player: playerView.player,
            hand: playerView.hand,
            marketplace: playerView.marketplaceCards,
            players: players,
            supply: playerView.supply,
            stock: playerView.stock,
            deckCount: playerView.deckCount,
            rules: rules
        )
    }

    public var handLimit: Int {
        rules.handLimitBase + (ownPlayer.tableau.count(of: .customsHouse) > 0 ? 2 : 0)
    }
}

public struct StrategistDecision: Equatable, Sendable {
    public let action: GameAction
    public let message: String

    public init(action: GameAction, message: String) {
        self.action = action
        self.message = message
    }
}

/// A deterministic baseline strategist. Its logger defaults to console output;
/// tests and other callers can inject a quiet or application-specific logger.
public struct AIStrategist: BotStrategy {
    public typealias View = StrategistObservation
    public typealias Action = GameAction

    private let personality: StrategistPersonality
    private let logger: @Sendable (String) -> Void

    public init(
        personality: StrategistPersonality = .aggressive,
        logger: @escaping @Sendable (String) -> Void = { print($0) }
    ) {
        self.personality = personality
        self.logger = logger
    }

    public func chooseAction(
        for view: StrategistObservation,
        legalActions: [GameAction]
    ) -> GameAction? {
        decide(for: view, legalActions: legalActions)?.action
    }

    public func decide(
        for observation: StrategistObservation,
        legalActions: [GameAction]
    ) -> StrategistDecision? {
        let decision: StrategistDecision?
        switch observation.phase {
        case .planning:
            decision = planningDecision(for: observation, legalActions: legalActions)
        case .additionalExchange(let remaining, let exchanged, let added):
            decision = additionalExchangeDecision(
                for: observation,
                legalActions: legalActions,
                remaining: remaining,
                excludedShips: exchanged.union(added)
            )
        case .trading:
            decision = tradingDecision(for: observation, legalActions: legalActions)
        }

        if let decision {
            logger(decision.message)
        }
        return decision
    }

    private func planningDecision(
        for observation: StrategistObservation,
        legalActions: [GameAction]
    ) -> StrategistDecision? {
        // Exchanges must improve the best projected payout; aggressive players invest before
        // exchanging, while conservative players prefer an immediate gain over a weak investment.
        let exchanges = legalActions.compactMap { action -> (GameAction, Int)? in
            guard isLegal(action, for: observation),
                  case .exchangeCube(let ship, let cubeIndex, let good) = action,
                  let changed = exchangeAdjustment(
                    ship: ship, cubeIndex: cubeIndex, to: good, in: observation
                  ) else { return nil }
            let before = bestPotentialPayout(for: observation)
            let after = bestPotentialPayout(for: observation, cubeAdjustments: changed)
            let gain = after - before
            return gain > 0 ? (action, gain) : nil
        }
        let bestExchange = exchanges.max { $0.1 < $1.1 }

        let purchases = legalActions.compactMap { action -> PurchaseEvaluation? in
            guard isLegal(action, for: observation),
                  case .buySpecialCard(let kind, let loadCubes) = action else { return nil }
            return purchaseEvaluation(
                kind: kind,
                loadCubes: loadCubes,
                observation: observation,
                exchangeGain: bestExchange?.1 ?? 0
            )
        }.max { $0.priority < $1.priority }

        if personality == .aggressive, let purchases {
            return decision(for: purchases.action, in: .planning, reason: purchases.reason)
        }

        if let bestExchange,
           purchases == nil || bestExchange.1 >= purchases!.immediateGain {
            let reason = "it improves the best projected delivery by \(bestExchange.1) coins"
            return decision(for: bestExchange.0, in: .planning, reason: reason)
        }

        if let purchases {
            return decision(for: purchases.action, in: .planning, reason: purchases.reason)
        }

        if let pass = legalActions.first(where: {
            $0 == .passPlanning && isLegal($0, for: observation)
        }) {
            return decision(for: pass, in: .planning, reason: "no profitable legal purchase or exchange is available")
        }
        return nil
    }

    private func additionalExchangeDecision(
        for observation: StrategistObservation,
        legalActions: [GameAction],
        remaining: Int,
        excludedShips: Set<Int>
    ) -> StrategistDecision? {
        let before = bestPotentialPayout(for: observation)
        let bestExchange = legalActions.compactMap { action -> (GameAction, Int)? in
            guard isLegal(action, for: observation),
                  case .exchangeCube(let ship, let cubeIndex, let good) = action,
                  !excludedShips.contains(ship),
                  let changed = exchangeAdjustment(
                    ship: ship, cubeIndex: cubeIndex, to: good, in: observation
                  ) else { return nil }
            let gain = bestPotentialPayout(for: observation, cubeAdjustments: changed) - before
            return gain > 0 ? (action, gain) : nil
        }.max { $0.1 < $1.1 }

        if let bestExchange {
            return decision(
                for: bestExchange.0,
                in: .planning,
                reason: "it improves the best projected delivery by \(bestExchange.1) coins"
            )
        }

        guard remaining > 0,
              let endPlanning = legalActions.first(where: {
                  $0 == .endPlanning && isLegal($0, for: observation)
              }) else { return nil }
        return decision(for: endPlanning, in: .planning, reason: "no profitable extra exchange is available")
    }

    private func tradingDecision(
        for observation: StrategistObservation,
        legalActions: [GameAction]
    ) -> StrategistDecision? {
        // Refill a short hand when drawing is legal; otherwise use the delivery with the
        // strongest expected payout, retaining a legal delivery as the fallback.
        let draw = legalActions.first(where: {
            $0 == .drawCards && isLegal($0, for: observation)
        })

        if observation.hand.count < 3, let draw {
            return decision(
                for: draw,
                in: .trading,
                reason: "the hand has only \(observation.hand.count) cards, so drawing builds future options"
            )
        }

        let deliveries = legalActions.compactMap { action -> (GameAction, DeliveryEvaluation)? in
            guard isLegal(action, for: observation),
                  case .deliverCards(let placements) = action,
                  let evaluation = deliveryEvaluation(placements, for: observation) else { return nil }
            return (action, evaluation)
        }
        if let bestDelivery = deliveries.max(by: { $0.1.strategyScore < $1.1.strategyScore }) {
            let reason = "delivering \(bestDelivery.1.cardCount) \(goodName(bestDelivery.1.good)) card(s) projects a \(bestDelivery.1.ownPayout)-coin payout"
            return decision(for: bestDelivery.0, in: .trading, reason: reason)
        }

        if let draw {
            return decision(for: draw, in: .trading, reason: "no legal delivery is available, so drawing keeps the hand playable")
        }
        if let skip = legalActions.first(where: {
            $0 == .skipTrading && isLegal($0, for: observation)
        }) {
            return decision(for: skip, in: .trading, reason: "the deck is empty and no legal delivery is available")
        }
        return nil
    }

    private struct PurchaseEvaluation {
        let action: GameAction
        let priority: Int
        let immediateGain: Int
        let reason: String
    }

    private func purchaseEvaluation(
        kind: SpecialCardKind,
        loadCubes: [GoodType],
        observation: StrategistObservation,
        exchangeGain: Int
    ) -> PurchaseEvaluation? {
        // Validate candidates again instead of trusting an external action list, then rank
        // income engines ahead of utility cards when their projected use justifies the cost.
        let entry = observation.rules.specialCardCatalog.entry(for: kind)
        let cubeAdjustments = loadCubes.reduce(into: [GoodType: Int]()) { counts, good in
            counts[good, default: 0] += 1
        }
        let before = bestPotentialPayout(for: observation)
        let extraAgreements = kind == .tradeAgreement ? 1 : 0
        let after = bestPotentialPayout(
            for: observation,
            cubeAdjustments: cubeAdjustments,
            extraTradeAgreements: extraAgreements
        )
        let immediateGain = max(0, after - before)
        let loadedMarketDemand = loadCubes.reduce(0) { $0 + marketDemand($1, in: observation) }
        let hasFutureTurns = observation.deckCount > 1

        let priority: Int
        let isIncomePurchase: Bool
        // These category weights put fleet and Trade Agreement investments ahead of utility cards.
        switch kind {
        case .ship:
            guard immediateGain > 0 || (hasFutureTurns && loadedMarketDemand > 0) else { return nil }
            priority = 100 + immediateGain * 4 + loadedMarketDemand
            isIncomePurchase = true
        case .largeShip:
            guard immediateGain > 0 || (hasFutureTurns && loadedMarketDemand > 0) else { return nil }
            priority = 105 + immediateGain * 4 + loadedMarketDemand
            isIncomePurchase = true
        case .tradeAgreement:
            let currentBest = bestPotentialPayout(for: observation)
            guard immediateGain > 0 || (hasFutureTurns && currentBest > observation.rules.tradeAgreementMinimumPayout) else {
                return nil
            }
            priority = 95 + immediateGain * 5 + (hasFutureTurns ? 1 : 0)
            isIncomePurchase = true
        case .crane:
            guard exchangeGain > 0 else { return nil }
            priority = 70 + exchangeGain * 3
            isIncomePurchase = false
        case .office:
            guard hasFutureTurns,
                  observation.hand.count < observation.handLimit,
                  observation.deckCount > 0 else { return nil }
            priority = 60 + (observation.hand.count < 3 ? 5 : 0)
            isIncomePurchase = false
        case .customsHouse:
            guard observation.hand.count >= observation.handLimit - 1 else { return nil }
            priority = 50
            isIncomePurchase = false
        }

        if personality == .conservative {
            let coinsAfterPurchase = observation.ownPlayer.coins - entry.price
            // Keep a small reserve and require an immediate projected return on coin investments.
            guard coinsAfterPurchase >= 5 else { return nil }
            if isIncomePurchase {
                guard immediateGain * 2 >= entry.price else { return nil }
            } else if kind == .crane {
                guard exchangeGain * 2 >= entry.price else { return nil }
            } else if kind == .office {
                guard observation.hand.count <= 2, observation.deckCount > 3 else { return nil }
            } else if kind == .customsHouse {
                guard observation.hand.count >= observation.handLimit - 1 else { return nil }
            }
        }

        let reason = "buying \(cardName(kind)) for \(entry.price) coins is the best affordable legal investment"
        return PurchaseEvaluation(
            action: .buySpecialCard(kind: kind, loadCubes: loadCubes),
            priority: priority,
            immediateGain: immediateGain,
            reason: reason
        )
    }

    private struct DeliveryEvaluation {
        let good: GoodType
        let cardCount: Int
        let ownPayout: Int
        let strategyScore: Int
    }

    private func deliveryEvaluation(
        _ placements: [DeliveryPlacement],
        for observation: StrategistObservation
    ) -> DeliveryEvaluation? {
        // Deliveries score against the new visible market and pay every player's matching cubes.
        guard let good = placements.first?.card.good else { return nil }
        let demandIncrease = placements.reduce(into: 0) { increase, placement in
            if observation.marketplace[placement.slot].good != good { increase += 1 }
        }
        let finalDemand = marketDemand(good, in: observation) + demandIncrease
        var ownPayout = 0
        var opponentPayout = 0

        for player in observation.players {
            let payout = payout(
                for: player,
                good: good,
                demand: finalDemand,
                observation: observation
            )
            guard payout <= Coins.maximumBalance - player.coins else { return nil }
            if player.player == observation.player {
                ownPayout = payout
            } else {
                // Conservative play strongly avoids creating demand that helps a current leader.
                let leaderWeight = player.coins > observation.ownPlayer.coins ? 3 : 1
                opponentPayout += payout * leaderWeight
            }
        }

        let strategyScore: Int
        switch personality {
        case .aggressive:
            strategyScore = ownPayout
        case .conservative:
            strategyScore = ownPayout - opponentPayout
        }
        return DeliveryEvaluation(
            good: good,
            cardCount: placements.count,
            ownPayout: ownPayout,
            strategyScore: strategyScore
        )
    }

    private func bestPotentialPayout(
        for observation: StrategistObservation,
        cubeAdjustments: [GoodType: Int] = [:],
        extraTradeAgreements: Int = 0
    ) -> Int {
        GoodType.allCases.map { good in
            let availableCards = observation.hand.filter { $0.good == good }.count
            let newSlots = observation.marketplace.filter { $0.good != good }.count
            let expectedDemand = marketDemand(good, in: observation)
                + min(availableCards, newSlots)
            return payout(
                for: observation.ownPlayer,
                good: good,
                demand: expectedDemand,
                observation: observation,
                cubeAdjustment: cubeAdjustments[good, default: 0],
                extraTradeAgreements: extraTradeAgreements
            )
        }.max() ?? 0
    }

    private func payout(
        for player: StrategistPlayerObservation,
        good: GoodType,
        demand: Int,
        observation: StrategistObservation,
        cubeAdjustment: Int = 0,
        extraTradeAgreements: Int = 0
    ) -> Int {
        let cubes = player.fleet.cubeCount(of: good)
            + (player.player == observation.player ? cubeAdjustment : 0)
        let basePayout = cubes * demand
        let agreements = player.tableau.count(of: .tradeAgreement)
            + (player.player == observation.player ? extraTradeAgreements : 0)
        guard basePayout > observation.rules.tradeAgreementMinimumPayout else {
            return basePayout
        }
        return basePayout + agreements * observation.rules.tradeAgreementBonusPerCard
    }

    private func exchangeAdjustment(
        ship: Int,
        cubeIndex: Int,
        to good: GoodType,
        in observation: StrategistObservation
    ) -> [GoodType: Int]? {
        guard observation.ownPlayer.fleet.ships.indices.contains(ship),
              observation.ownPlayer.fleet.ships[ship].cubes.indices.contains(cubeIndex) else {
            return nil
        }
        let oldGood = observation.ownPlayer.fleet.ships[ship].cubes[cubeIndex].good
        guard oldGood != good else { return nil }
        return [oldGood: -1, good: 1]
    }

    private func isLegal(_ action: GameAction, for observation: StrategistObservation) -> Bool {
        switch (observation.phase, action) {
        case (.planning, .passPlanning):
            return true
        case (.planning, .exchangeCube(let ship, let cubeIndex, let good)):
            return validExchange(ship, cubeIndex, good, observation: observation)
        case (.planning, .buySpecialCard(let kind, let goods)):
            return validPurchase(kind, goods, observation: observation)
        case (.additionalExchange(let remaining, let exchanged, let added), .exchangeCube(let ship, let cubeIndex, let good)):
            return remaining > 0 && !exchanged.contains(ship) && !added.contains(ship)
                && validExchange(ship, cubeIndex, good, observation: observation)
        case (.additionalExchange(let remaining, _, _), .endPlanning):
            return remaining > 0
        case (.trading, .deliverCards(let placements)):
            return validDelivery(placements, observation: observation)
        case (.trading, .drawCards):
            let count = min(2, observation.deckCount)
            return count > 0 && observation.handLimit - observation.hand.count >= count
        case (.trading, .skipTrading):
            return observation.deckCount == 0
        default:
            return false
        }
    }

    private func validExchange(
        _ ship: Int,
        _ cubeIndex: Int,
        _ good: GoodType,
        observation: StrategistObservation
    ) -> Bool {
        guard observation.ownPlayer.fleet.ships.indices.contains(ship),
              observation.ownPlayer.fleet.ships[ship].cubes.indices.contains(cubeIndex),
              observation.ownPlayer.fleet.ships[ship].cubes[cubeIndex].good != good else {
            return false
        }
        return observation.supply.available(of: good) > 0
    }

    private func validPurchase(
        _ kind: SpecialCardKind,
        _ goods: [GoodType],
        observation: StrategistObservation
    ) -> Bool {
        let player = observation.ownPlayer
        let entry = observation.rules.specialCardCatalog.entry(for: kind)
        guard player.coins >= entry.price,
              observation.stock.available(of: kind) > 0,
              entry.ownershipLimit.map({ player.tableau.count(of: kind) < $0 }) ?? true else {
            return false
        }

        switch kind {
        case .ship:
            guard goods.count == Ship.Kind.standard.capacity else { return false }
        case .largeShip:
            guard (1...Ship.Kind.large.capacity).contains(goods.count) else { return false }
        default:
            guard goods.isEmpty else { return false }
        }

        return GoodType.allCases.allSatisfy { good in
            goods.filter { $0 == good }.count <= observation.supply.available(of: good)
        }
    }

    private func validDelivery(
        _ placements: [DeliveryPlacement],
        observation: StrategistObservation
    ) -> Bool {
        guard let first = placements.first,
              placements.count <= Marketplace.slotCount,
              placements.allSatisfy({ $0.card.good == first.card.good }),
              placements.allSatisfy({ observation.marketplace.indices.contains($0.slot) }),
              Set(placements.map(\.slot)).count == placements.count,
              observation.hand.filter({ $0.good == first.card.good }).count >= placements.count else {
            return false
        }
        return deliveryEvaluation(placements, for: observation) != nil
    }

    private func decision(
        for action: GameAction,
        in phase: StrategistPhase,
        reason: String
    ) -> StrategistDecision {
        let phaseName = phase == .trading ? "Phase 2" : "Phase 1"
        return StrategistDecision(
            action: action,
            message: "\(phaseName): Bot made a decision to \(actionName(action)); \(reason)."
        )
    }

    private func actionName(_ action: GameAction) -> String {
        switch action {
        case .exchangeCube(let ship, let cubeIndex, let good):
            return "exchange the \(cubeIndex == 0 ? "first" : "next") cube on ship \(ship) for \(goodName(good))"
        case .buySpecialCard(let kind, let goods):
            let load = goods.isEmpty ? "" : " loaded with \(goods.map(goodName).joined(separator: " and "))"
            return "buy a \(cardName(kind))\(load)"
        case .passPlanning:
            return "pass on a purchase or exchange"
        case .endPlanning:
            return "end Phase 1"
        case .deliverCards(let placements):
            return "deliver \(placements.count) \(goodName(placements[0].card.good)) card(s)"
        case .drawCards:
            return "draw goods cards"
        case .skipTrading:
            return "skip Phase 2"
        case .draftCube(let good, let ship):
            return "draft a \(goodName(good)) cube onto ship \(ship)"
        }
    }

    private func marketDemand(_ good: GoodType, in observation: StrategistObservation) -> Int {
        observation.marketplace.filter { $0.good == good }.count
    }

    private func cardName(_ kind: SpecialCardKind) -> String {
        switch kind {
        case .ship: return "ship"
        case .largeShip: return "large ship"
        case .office: return "office"
        case .crane: return "crane"
        case .tradeAgreement: return "trade agreement"
        case .customsHouse: return "customs house"
        }
    }

    private func goodName(_ good: GoodType) -> String {
        switch good {
        case .sugar: return "sugar"
        case .indigo: return "indigo"
        case .spices: return "spices"
        case .tea: return "tea"
        case .silk: return "silk"
        case .lumber: return "lumber"
        }
    }
}
