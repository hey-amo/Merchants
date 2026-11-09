import Foundation
import Testing
@testable import MerchantsGame

@Suite("Game session lifecycle")
struct GameSessionTests {
    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func completeGamePublishesDeterministicUpdates(rule: EndGameRule) async throws {
        let players = [PlayerID("first"), PlayerID("second")]
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let config = try GameConfiguration(playerIDs: players, seed: 42, rules: rules)
        let session = try GameSession(configuration: config)
        var expected = try GameState(configuration: config)
        var updates = await session.updates().makeAsyncIterator()
        var turns = [0, 0]
        var actions = 0

        #expect(await session.snapshot() == expected)
        do {
            _ = try await session.standings()
            Issue.record("Standings must not be available before game over")
        } catch {
            #expect(error as? GameEndingError == .gameNotOver)
        }
        do {
            try await session.send(.drawCards, by: players[0])
            Issue.record("Draw must not be accepted during draft")
        } catch {
            #expect(error.error == .invalidAction)
            #expect(await session.snapshot() == expected)
        }

        while expected.ending.status != .finished && actions < 1_000 {
            let seat = try expected.turn?.currentSeat ?? expected.draft.nextSeat()
            let player = players[seat]
            let choices = try await session.legalActions(for: player)
            let view = try await session.playerView(for: player)
            #expect(view.hand == expected.hands[seat].contents)
            let action = try #require(GamePassiveBot().chooseAction(for: view, legalActions: choices))
            let (next, events) = try GameEngine.apply(action, by: player, to: expected)
            try await session.send(action, by: player)
            let update = try #require(await updates.next())
            #expect(update == GameUpdate(newState: next, events: events))
            #expect(await session.snapshot() == next)
            try GameInvariants.validate(next)
            if events.contains(.turnEnded(player: player)) { turns[seat] += 1 }
            expected = next
            actions += 1
        }
        #expect(actions < 1_000)
        #expect(expected.ending.status == .finished)
        #expect(await updates.next() == nil)
        let standings = try await session.standings()
        let expectedStandings = try expected.ending.standings(players: players, bank: expected.bank)
        #expect(standings == expectedStandings)
        if rule == .oneMoreTurn { #expect(turns[0] == turns[1]) }
        do {
            try await session.send(.passPlanning, by: players[0])
            Issue.record("Finished session accepted an action")
        } catch {
            #expect(error.error == .gameEnding(.alreadyEnded))
        }
    }

    @Test func restoredSessionRetainsPlayableState() async throws {
        let players = [PlayerID("first"), PlayerID("second")]
        let configuration = try GameConfiguration(playerIDs: players, seed: 31)
        let state = try GameState(configuration: configuration)
        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(GameState.self, from: data)
        let session = try GameSession(restoring: restored)
        let seat = try restored.draft.nextSeat()
        let player = players[seat]
        let actions = try await session.legalActions(for: player)
        let action = try #require(actions.first)
        let (expected, _) = try GameEngine.apply(action, by: player, to: restored)
        try await session.send(action, by: player)
        #expect(await session.snapshot() == expected)
    }

    @Test func concurrentSubmissionsCommitOnlyOneAction() async throws {
        let players = [PlayerID("first"), PlayerID("second")]
        let config = try GameConfiguration(playerIDs: players, seed: 42, firstPlayer: .fixed(players[0]))
        let session = try GameSession(configuration: config)
        var state = await session.snapshot()
        while state.turn == nil {
            let seat = try state.draft.nextSeat()
            let legal = try await session.legalActions(for: players[seat])
            try await session.send(try #require(legal.first), by: players[seat])
            state = await session.snapshot()
        }
        let snapshot = state
        let stream = await session.updates()
        var iterator = stream.makeAsyncIterator()
        let successes = await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for _ in 0..<2 {
                group.addTask {
                    do {
                        try await session.send(.passPlanning, by: players[0])
                        return true
                    } catch let rejection as ActionRejection {
                        #expect(rejection.error == .turnFlow(.wrongPhase))
                        return false
                    } catch {
                        Issue.record("Unexpected submission error: \(error)")
                        return false
                    }
                }
            }
            var count = 0
            for await success in group where success { count += 1 }
            return count
        }
        #expect(successes == 1)
        let update = try #require(await iterator.next())
        let (expected, events) = try GameEngine.apply(.passPlanning, by: players[0], to: snapshot)
        #expect(update == GameUpdate(newState: expected, events: events))
        #expect(await session.snapshot() == expected)
    }

    @Test func sessionRunsDeliveryScoringAndSpecialCardPurchase() async throws {
        let players = [PlayerID("first"), PlayerID("second")]
        let session = try GameSession(configuration: GameConfiguration(playerIDs: players, seed: 42))
        var updates = await session.updates().makeAsyncIterator()
        var scored = false
        var bought = false
        for _ in 0..<1_000 {
            let state = await session.snapshot()
            if state.ending.status == .finished { break }
            let seat = try state.turn?.currentSeat ?? state.draft.nextSeat()
            let player = players[seat]
            let actions = try await session.legalActions(for: player)
            let purchase = actions.first {
                if case .buySpecialCard = $0 { return true }
                return false
            }
            let action: GameAction
            if let purchase, !bought {
                action = purchase
            } else if actions.contains(.passPlanning) {
                action = .passPlanning
            } else if actions.contains(.drawCards) {
                action = .drawCards
            } else {
                action = try #require(actions.first)
            }
            try await session.send(action, by: player)
            let update = try #require(await updates.next())
            if update.events.contains(where: {
                if case .coinsEarned = $0 { return true }
                return false
            }) { scored = true }
            if update.events.contains(where: {
                if case .specialCardBought = $0 { return true }
                return false
            }) { bought = true }
        }
        #expect(scored)
        #expect(bought)
        #expect(await session.snapshot().ending.status == .finished)
    }
}
