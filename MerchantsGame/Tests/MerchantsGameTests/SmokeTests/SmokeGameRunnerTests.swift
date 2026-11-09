import Foundation
import Testing
@testable import MerchantsGame

@Suite("Smoke game runner")
struct SmokeGameRunnerTests {
    private actor Recorder {
        private(set) var messages: [String] = []
        func append(_ message: String) { messages.append(message) }
    }

    private actor StubSession: SmokeSession {
        var state: GameState
        let player: PlayerID
        private(set) var steps = 0

        init(state: GameState, player: PlayerID) {
            self.state = state
            self.player = player
        }

        func snapshot() -> GameState { state }

        func step() throws -> BotGameStep? {
            steps += 1
            let (next, _) = try GameEngine.apply(.drawCards, by: player, to: state)
            state = next
            return BotGameStep(player: player, action: .drawCards, message: "Drew a card", state: next)
        }
    }

    private func configuration() throws -> GameConfiguration {
        try GameConfiguration(
            playerIDs: [PlayerID("Test bot 1"), PlayerID("Test bot 2")],
            seed: 42
        )
    }

    @Test(arguments: [1, 10])
    func stopsAfterRequestedCompletedTurns(rounds: Int) async throws {
        let session = try BotGameSession(configuration: configuration(), logger: { _ in })
        let recorder = Recorder()
        let runner = SmokeGameRunner(
            session: session, roundLimit: rounds,
            delay: {}, log: { await recorder.append($0) }
        )
        let result = try await runner.run()
        #expect(result == .init(completedRounds: rounds, reason: .roundLimit))
        let messages = await recorder.messages
        #expect(messages.filter { $0.hasPrefix("Round ") }.count == rounds)
        #expect(messages.last?.contains("round limit reached") == true)
        #expect(messages.filter { $0.hasPrefix("Decision:") }.count > rounds)
    }

    @Test func outputUsesOnlyActivePlayersHand() async throws {
        let config = try configuration()
        let session = try BotGameSession(configuration: config, logger: { _ in })
        let initial = await session.snapshot()
        let seat = try initial.draft.nextSeat()
        let active = config.playerIDs[seat]
        let view = try initial.playerView(for: active)
        let hand = view.hand.map { String(describing: $0.good).capitalized }.joined(separator: ", ")
        let recorder = Recorder()
        let runner = SmokeGameRunner(
            session: session, roundLimit: 1,
            delay: {}, log: { await recorder.append($0) }
        )
        _ = try await runner.run()
        let messages = await recorder.messages
        let first = try #require(messages.first { $0.hasPrefix("\n---") })
        #expect(messages[0].contains("Players: Test bot 1, Test bot 2"))
        #expect(first.contains("Draft: \(active.rawValue)"))
        #expect(first.contains("Marketplace:"))
        #expect(first.contains("Deck remaining: \(view.deckCount)"))
        #expect(first.contains("Cube supply:"))
        #expect(first.contains("Coins: Test bot 1: 0, Test bot 2: 0"))
        #expect(first.contains("\(active.rawValue)'s portfolio:"))
        #expect(first.contains("Hand: \(hand)"))
        #expect(first.components(separatedBy: "Hand:").count == 2)
        #expect(!first.contains("\(config.playerIDs[1 - seat].rawValue)'s portfolio:"))
    }

    @Test func reportsPaymentsAndUpdatedBalances() async throws {
        let session = try BotGameSession(configuration: configuration(), logger: { _ in })
        let recorder = Recorder()
        let runner = SmokeGameRunner(
            session: session, roundLimit: 10,
            delay: {}, log: { await recorder.append($0) }
        )
        _ = try await runner.run()
        let reports = await recorder.messages.filter { $0.hasPrefix("Micro report:") }
        #expect(!reports.isEmpty)
        #expect(reports.contains { $0.contains("paid ") && $0.contains("(balance:") })
        #expect(reports.allSatisfy { $0.contains("Balances: Test bot 1:") && $0.contains("Test bot 2:") })
    }

    @Test func rejectsInvalidRoundLimitsBeforeTakingAnAction() async throws {
        let session = try BotGameSession(configuration: configuration(), logger: { _ in })
        let initial = await session.snapshot()
        for limit in [0, 11] {
            let runner = SmokeGameRunner(session: session, roundLimit: limit, delay: {}, log: { _ in })
            do {
                _ = try await runner.run()
                Issue.record("Expected an invalid round limit error")
            } catch {
                #expect(error as? SmokeGameError == .invalidRoundLimit)
            }
        }
        #expect(await session.snapshot() == initial)
    }

    @Test func cancellationBeforeMoveLeavesTheSessionUntouched() async throws {
        let session = try BotGameSession(configuration: configuration(), logger: { _ in })
        let initial = await session.snapshot()
        let runner = SmokeGameRunner(
            session: session, roundLimit: 1,
            delay: { throw CancellationError() }, log: { _ in }
        )
        do {
            _ = try await runner.run()
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            #expect(await session.snapshot() == initial)
        }
    }

    @Test func cancellationDuringDelayLeavesTheSessionUntouched() async throws {
        let session = try BotGameSession(configuration: configuration(), logger: { _ in })
        let initial = await session.snapshot()
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        let runner = SmokeGameRunner(
            session: session, roundLimit: 1,
            delay: {
                continuation.yield(())
                try await Task.sleep(nanoseconds: 60_000_000_000)
            },
            log: { _ in }
        )
        let task = Task { try await runner.run() }
        var iterator = signals.makeAsyncIterator()
        _ = await iterator.next()
        task.cancel()
        continuation.finish()
        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            #expect(await session.snapshot() == initial)
        }
    }

    @Test func stopsImmediatelyWhenTheDeckEmpties() async throws {
        let config = try configuration()
        var state = try GameState(configuration: config)
        while state.turn == nil {
            let seat = try state.draft.nextSeat()
            let player = config.playerIDs[seat]
            let action = try #require(state.legalActions(for: player).first)
            (state, _) = try GameEngine.apply(action, by: player, to: state)
        }
        let player = config.playerIDs[try #require(state.turn).currentSeat]
        (state, _) = try GameEngine.apply(.passPlanning, by: player, to: state)
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        let session = StubSession(state: state, player: player)
        let recorder = Recorder()
        let runner = SmokeGameRunner(
            session: session, roundLimit: 10,
            delay: {}, log: { await recorder.append($0) }
        )
        let result = try await runner.run()
        #expect(result == .init(completedRounds: 1, reason: .deckEmpty))
        #expect(await session.steps == 1)
        #expect(await recorder.messages.last?.contains("deck empty") == true)
    }
}
