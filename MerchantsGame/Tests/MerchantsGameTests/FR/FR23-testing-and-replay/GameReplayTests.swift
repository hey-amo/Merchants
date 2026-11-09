import Foundation
import Testing
@testable import MerchantsGame

@Suite("Seeded games and replay")
struct GameReplayTests {
    private struct Step: Codable, Equatable {
        let player: PlayerID
        let action: GameAction
    }

    private enum Strategy {
        case random, passive, deliver
    }

    private func verifyState(_ state: GameState) throws {
        try GameInvariants.validate(state)
        for good in GoodType.allCases {
            #expect(state.supply.available(of: good) + state.fleets.reduce(0) { $0 + $1.cubeCount(of: good) } == 5)
        }
        for fleet in state.fleets {
            for ship in fleet.ships {
                #expect(ship.cubes.count <= ship.kind.capacity)
                if state.turn != nil { #expect(!ship.cubes.isEmpty) }
            }
        }
        #expect(state.deck.remaining + state.hands.reduce(0) { $0 + $1.count } + state.marketplace.totalCardCount == 60)
        #expect(state.marketplace.visibleCards.count == 6)
        for (seat, hand) in state.hands.enumerated() {
            let limit = state.configuration.rules.handLimitBase
                + SpecialCardEffects(tableau: state.tableaux[seat], rules: state.configuration.rules).handLimitBonus
            #expect(hand.count <= limit)
            #expect(try state.bank.balance(of: state.configuration.playerIDs[seat]).available >= 0)
        }
        for kind in SpecialCardKind.allCases {
            let owned = state.tableaux.reduce(0) { $0 + $1.count(of: kind) }
            let initial = try state.configuration.rules.specialCardCatalog.stock(for: kind, playerCount: state.hands.count)
            #expect(state.stock.available(of: kind) + owned == initial)
            if let limit = state.stock.catalog.entry(for: kind).ownershipLimit {
                #expect(state.tableaux.allSatisfy { $0.count(of: kind) <= limit })
            }
        }
        if let turn = state.turn {
            #expect(turn.order == state.draft.order)
            if state.ending.status == .finished {
                #expect(turn.status == .finished)
            } else {
                if case .active = turn.status {} else { Issue.record("An unfinished game must have an active player") }
            }
            if case .active(.planning(let progress)) = turn.status {
                #expect(progress.shipsExchanged.isDisjoint(with: progress.shipsAddedThisTurn))
            }
        }
    }

    private func run(count: Int, rule: EndGameRule, seed: UInt64, strategy: Strategy) throws {
        let players = (0..<count).map { PlayerID("p\($0)") }
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(playerIDs: players, seed: seed, rules: rules)
        var state = try GameState(configuration: configuration)
        var random = SeededRandomSource(seed: seed &+ 17)
        var steps: [Step] = []
        var allEvents: [[GameEvent]] = []
        var allStates: [GameState] = []
        var turnCounts = Array(repeating: 0, count: count)
        var turnPotential = 2 * state.deck.remaining + state.hands.reduce(0) { $0 + $1.count }
        let first = state.draft.order.first
        var actionCount = 0
        while state.ending.status != .finished && actionCount < 1_000 {
            try verifyState(state)
            let seat = try state.turn?.currentSeat ?? state.draft.nextSeat()
            let player = players[seat]
            let legal = try state.legalActions(for: player)
            #expect(!legal.isEmpty)
            let action: GameAction
            switch strategy {
            case .random:
                action = legal[Int(random.next() % UInt64(legal.count))]
            case .passive:
                action = try #require(PassiveBot<PlayerView, GameAction>().chooseAction(
                    for: state.playerView(for: player), legalActions: legal))
            case .deliver:
                if let delivery = legal.first(where: { if case .deliverCards = $0 { return true }; return false }) {
                    action = delivery
                } else {
                    action = try #require(legal.first)
                }
            }
            let before = state
            if case .exchangeCube(let ship, _, _) = action,
               case .active(.planning(let progress)) = state.turn?.status {
                #expect(!progress.shipsExchanged.contains(ship))
                #expect(!progress.shipsAddedThisTurn.contains(ship))
            }
            let (next, events) = try GameEngine.apply(action, by: player, to: state)
            #expect(!events.isEmpty)
            #expect(next.random == before.random)
            if actionCount.isMultiple(of: 20) {
                let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(before))
                let (restoredNext, restoredEvents) = try GameEngine.apply(action, by: player, to: restored)
                #expect(restored == before)
                #expect(restoredNext == next)
                #expect(restoredEvents == events)
            }
            for owner in players {
                let credited = events.reduce(0) { total, event in
                    guard case .coinsEarned(let recipient, let amount, let reason) = event,
                          recipient == owner else { return total }
                    switch reason {
                    case .deliveryPayout, .tradeAgreementBonus: return total + amount
                    case .specialCardPurchase:
                        Issue.record("A purchase cannot be a coin-earning event")
                        return total
                    }
                }
                let spent: Int
                if owner == player, case .buySpecialCard(let kind, _) = action {
                    spent = before.configuration.rules.specialCardCatalog.entry(for: kind).price
                } else {
                    spent = 0
                }
                let oldBalance = try before.bank.balance(of: owner).available
                let newBalance = try next.bank.balance(of: owner).available
                #expect(newBalance - oldBalance == credited - spent)
            }
            let completedTurn = events.contains(.turnEnded(player: player)) ||
                (next.ending.status == .finished && before.ending.status == .ongoing)
            if completedTurn {
                turnCounts[seat] += 1
                let potential = 2 * next.deck.remaining + next.hands.reduce(0) { $0 + $1.count }
                if before.ending.status == .ongoing { #expect(potential < turnPotential) }
                turnPotential = potential
            }
            #expect(next.draft.order.first == first)
            steps.append(Step(player: player, action: action))
            allEvents.append(events)
            allStates.append(next)
            state = next
            try verifyState(state)
            actionCount += 1
        }
        #expect(state.ending.status == .finished)
        #expect(actionCount < 1_000)
        #expect(turnCounts.reduce(0, +) <= 110)
        if rule == .oneMoreTurn { #expect(Set(turnCounts).count == 1) }
        try verifyState(state)

        let encodedSteps = try JSONEncoder().encode(steps)
        let replaySteps = try JSONDecoder().decode([Step].self, from: encodedSteps)
        let replayEvents = try JSONDecoder().decode([[GameEvent]].self, from: JSONEncoder().encode(allEvents))
        #expect(replaySteps == steps)
        var replay = try GameState(configuration: configuration)
        for (index, step) in replaySteps.enumerated() {
            let (next, events) = try GameEngine.apply(step.action, by: step.player, to: replay)
            #expect(events == replayEvents[index])
            #expect(next == allStates[index])
            replay = next
        }
        #expect(replay == state)
    }

    @Test func seededGamesAndReplayAcrossPlayerCountsAndRules() throws {
        for count in 2...4 {
            for rule in [EndGameRule.immediate, .oneMoreTurn] {
                for seed in UInt64(0)..<10 {
                    try run(count: count, rule: rule, seed: seed, strategy: .random)
                }
            }
        }
    }

    @Test func passiveAndDeliveryStrategiesTerminate() throws {
        for count in 2...4 {
            for rule in [EndGameRule.immediate, .oneMoreTurn] {
                try run(count: count, rule: rule, seed: 11, strategy: .passive)
                try run(count: count, rule: rule, seed: 12, strategy: .deliver)
            }
        }
    }

    @Test(arguments: 2...4, [EndGameRule.immediate, .oneMoreTurn])
    func EC18RestoredGameContinuesAtEveryPhase(count: Int, rule: EndGameRule) throws {
        let players = (0..<count).map { PlayerID("p\($0)") }
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(
            playerIDs: players, seed: 56, firstPlayer: .fixed(players[1]), rules: rules
        )
        var state = try GameState(configuration: configuration)
        var sawDraft = false
        var sawPlanning = false
        var sawTrading = false
        var sawFinalRound = false
        var actions = 0
        while state.ending.status != .finished && actions < 500 {
            if state.turn == nil { sawDraft = true }
            if case .active(.planning) = state.turn?.status { sawPlanning = true }
            if state.turn?.status == .active(.trading) { sawTrading = true }
            if case .finalRound = state.ending.status { sawFinalRound = true }
            let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
            #expect(restored == state)
            let seat = try state.turn?.currentSeat ?? state.draft.nextSeat()
            let player = players[seat]
            let legal = try state.legalActions(for: player)
            let action: GameAction
            if state.turn == nil {
                action = try #require(legal.first)
            } else if legal.contains(.passPlanning) {
                action = .passPlanning
            } else if rule == .oneMoreTurn, state.ending.status == .ongoing,
                      seat == state.draft.order.last, state.deck.remaining <= 2 {
                action = try #require(legal.first { if case .deliverCards = $0 { return true }; return false })
            } else if legal.contains(.drawCards) {
                action = .drawCards
            } else if legal.contains(.skipTrading) {
                action = .skipTrading
            } else {
                action = try #require(legal.first { if case .deliverCards = $0 { return true }; return false })
            }
            let (next, events) = try GameEngine.apply(action, by: player, to: state)
            let (restoredNext, restoredEvents) = try GameEngine.apply(action, by: player, to: restored)
            #expect(restoredNext == next)
            #expect(restoredEvents == events)
            state = next
            actions += 1
        }
        #expect(state.ending.status == .finished)
        #expect(actions < 500)
        #expect(sawDraft && sawPlanning && sawTrading)
        if rule == .oneMoreTurn { #expect(sawFinalRound) }
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state)) == state)
    }

    @Test func EC7EC17EC37InitialDealAndSameColourDraft() throws {
        for count in 2...4 {
            let players = (0..<count).map { PlayerID("p\($0)") }
            let configuration = try GameConfiguration(playerIDs: players, seed: 7, firstPlayer: .fixed(players[0]))
            var state = try GameState(configuration: configuration)
            #expect(state.deck.remaining == 60 - count * 3 - 6)
            #expect(state.hands.allSatisfy { $0.count == 3 })
            #expect(state.bank.standings.values.allSatisfy { $0.available == 0 })
            while state.turn == nil {
                let seat = try state.draft.nextSeat()
                let ship = try #require(state.fleets[seat].ships.firstIndex { $0.cubes.isEmpty })
                let good: GoodType = seat == 0 ? .tea : .sugar
                let availableGood: GoodType = state.supply.available(of: good) > 0 ? good : .silk
                (state, _) = try GameEngine.apply(
                    .draftCube(good: availableGood, ship: ship), by: players[seat], to: state
                )
                try verifyState(state)
            }
            #expect(state.fleets[0].ships.map { $0.cubes[0].good } == [.tea, .tea])
            let purchase = GameAction.buySpecialCard(kind: .office, loadCubes: [])
            #expect(throws: ActionRejection(
                error: .banking(.coin(player: .insufficientFunds(required: 8, available: 0))),
                action: purchase, player: players[0]
            )) { try GameEngine.apply(purchase, by: players[0], to: state) }
            #expect(!(try state.legalActions(for: players[0])).contains(purchase))
        }
    }
}
