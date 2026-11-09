// Validates relationships between independently-owned values in a GameState.
// Does not mutate state or duplicate action-rule validation.
public enum GameInvariants {
    private static let totalGoodsCards = 60

    public static func validate(_ state: GameState) throws(GameStateError) {
        let players = state.configuration.playerIDs
        let playerIDs = Set(players)
        guard players.count == playerIDs.count,
              state.hands.count == players.count,
              state.fleets.count == players.count,
              state.tableaux.count == players.count,
              Set(state.bank.standings.keys) == playerIDs,
              state.stock.playerCount == players.count,
              state.stock.catalog == state.configuration.rules.specialCardCatalog,
              state.marketplace.visibleCards.count == Marketplace.slotCount,
              state.marketplace.totalCardCount >= Marketplace.slotCount else {
            throw .invalidPlayerState
        }

        guard state.deck.remaining
                + state.hands.reduce(0, { $0 + $1.count })
                + state.marketplace.totalCardCount == totalGoodsCards else {
            throw .cardCountMismatch
        }
        for good in GoodType.allCases {
            let count = state.deck.count(of: good)
                + state.hands.reduce(0) { $0 + $1.count(of: good) }
                + state.marketplace.count(of: good)
            guard count == 10 else { throw .cardCountMismatch }
        }

        for seat in players.indices {
            let effects = SpecialCardEffects(
                tableau: state.tableaux[seat],
                rules: state.configuration.rules
            )
            let handLimit = state.configuration.rules.handLimitBase + effects.handLimitBonus
            guard state.hands[seat].count <= handLimit else {
                throw .handOverLimit
            }
        }

        guard state.bank.standings.values.allSatisfy({
            $0.available >= 0 && $0.available <= Coins.maximumBalance
        }) else {
            throw .negativeBalance
        }

        for good in GoodType.allCases {
            let loaded = state.fleets.reduce(0) { $0 + $1.cubeCount(of: good) }
            guard state.supply.available(of: good) + loaded == CubeSupply.cubesPerGood else {
                throw .cubeCountMismatch
            }
        }

        for fleet in state.fleets {
            guard fleet.ships.allSatisfy({ $0.cubes.count <= $0.kind.capacity }) else {
                throw .shipOverCapacity
            }
        }

        for kind in SpecialCardKind.allCases {
            guard let initial = try? state.stock.catalog.stock(
                for: kind,
                playerCount: players.count
            ) else {
                throw .invalidSpecialCardStock
            }
            var remaining = initial
            for tableau in state.tableaux {
                let count = tableau.count(of: kind)
                guard count <= remaining,
                      state.stock.catalog.entry(for: kind).ownershipLimit.map({ count <= $0 }) ?? true else {
                    throw .invalidSpecialCardStock
                }
                remaining -= count
            }
            guard state.stock.available(of: kind) == remaining else {
                throw .invalidSpecialCardStock
            }
        }

        for seat in players.indices {
            let fleet = state.fleets[seat]
            let tableau = state.tableaux[seat]
            let standardShips = fleet.ships.filter { $0.kind == .standard }.count
            let largeShips = fleet.ships.filter { $0.kind == .large }.count
            guard standardShips >= 2,
                  standardShips - 2 == tableau.count(of: .ship),
                  largeShips == tableau.count(of: .largeShip) else {
                throw .invalidFleet
            }
        }

        try validateTurnState(state)
    }

    private static func validateTurnState(_ state: GameState) throws(GameStateError) {
        let order = state.draft.order
        guard order.count == state.configuration.playerIDs.count,
              state.ending.order == order,
              state.ending.rule == state.configuration.rules.endGameRule else {
            throw .invalidTurnState
        }
        if case .fixed(let firstPlayer) = state.configuration.firstPlayer,
           state.configuration.playerIDs.firstIndex(of: firstPlayer) != order.first {
            throw .invalidTurnState
        }

        guard let turn = state.turn else {
            guard !state.draft.isComplete,
                  state.fleets == state.draft.fleets,
                  state.supply == state.draft.supply,
                  state.ending.status == .ongoing,
                  state.hands.allSatisfy({ $0.count == 3 }),
                  state.marketplace.totalCardCount == Marketplace.slotCount,
                  state.bank.standings.values.allSatisfy({ $0.available == 0 }),
                  state.tableaux.allSatisfy({ tableau in
                      SpecialCardKind.allCases.allSatisfy { tableau.count(of: $0) == 0 }
                  }) else {
                throw .invalidTurnState
            }
            return
        }

        guard state.draft.isComplete,
              turn.order == order else {
            throw .invalidTurnState
        }
        guard state.fleets.allSatisfy({ fleet in
            fleet.ships.count >= 2 && fleet.ships.prefix(2).allSatisfy { $0.kind == .standard }
        }) else {
            throw .invalidTurnState
        }
        guard state.fleets.allSatisfy({
            $0.ships.allSatisfy { !$0.cubes.isEmpty }
        }) else {
            throw .shipNotFull
        }

        switch (state.ending.status, turn.status) {
        case (.ongoing, .active):
            guard !state.deck.isEmpty else { throw .invalidTurnState }
        case (.finalRound(let nextSeat), .active):
            guard state.deck.isEmpty, nextSeat == turn.currentSeat else { throw .invalidTurnState }
        case (.finished, .finished):
            guard state.deck.isEmpty else { throw .invalidTurnState }
        default:
            throw .invalidTurnState
        }
        if case .active(.planning(let progress)) = turn.status {
            let ships = state.fleets[turn.currentSeat].ships
            guard progress.shipsExchanged.allSatisfy(ships.indices.contains),
                  progress.shipsAddedThisTurn.allSatisfy(ships.indices.contains) else {
                throw .invalidTurnState
            }
            let cranes = state.tableaux[turn.currentSeat].count(of: .crane)
            switch progress.baseAction {
            case .exchange:
                guard progress.extrasAllowed == cranes else { throw .invalidTurnState }
            case .buy(.crane):
                guard cranes > 0 else { throw .invalidTurnState }
            default:
                break
            }
        }

    }
}
