import Foundation
import Testing
@testable import MerchantsGame

@Suite("Seeded games and replay")
struct GameReplayTests {
    private struct Step: Equatable {
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
                if state.turn != nil { #expect(ship.cubes.count == ship.kind.capacity) }
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
            let beforeCoins = before.bank.standings.values.reduce(0) { $0 + $1.available }
            let afterCoins = next.bank.standings.values.reduce(0) { $0 + $1.available }
            let credited = events.reduce(0) { total, event in
                if case .coinsEarned(_, let amount, _) = event { return total + amount }
                return total
            }
            let spent: Int
            if case .buySpecialCard(let kind, _) = action {
                spent = before.configuration.rules.specialCardCatalog.entry(for: kind).price
            } else {
                spent = 0
            }
            #expect(afterCoins - beforeCoins == credited - spent)
            if events.contains(.turnEnded(player: player)) {
                turnCounts[seat] += 1
                let potential = 2 * next.deck.remaining + next.hands.reduce(0) { $0 + $1.count }
                if before.ending.status == .ongoing { #expect(potential < turnPotential) }
                turnPotential = potential
            }
            #expect(next.draft.order.first == first)
            steps.append(Step(player: player, action: action))
            allEvents.append(events)
            state = next
            actionCount += 1
        }
        #expect(state.ending.status == .finished)
        #expect(actionCount < 1_000)
        #expect(turnCounts.reduce(0, +) < 110)
        if rule == .oneMoreTurn { #expect(Set(turnCounts).count == 1) }
        try verifyState(state)

        var replay = try GameState(configuration: configuration)
        for (index, step) in steps.enumerated() {
            let (next, events) = try GameEngine.apply(step.action, by: step.player, to: replay)
            #expect(events == allEvents[index])
            #expect(next.random == state.random)
            replay = next
        }
        #expect(replay == state)
    }

    @Test func seededGamesAndReplayAcrossPlayerCountsAndRules() throws {
        for count in 2...4 {
            for rule in [EndGameRule.immediate, .oneMoreTurn] {
                for seed in UInt64(0)..<4 {
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
}
