// Tests FR20 action serialization, successful update publication, stream completion, and cleanup.
// Does not test game rules already covered by the engine's focused suites.

import Testing
@testable import MerchantsGame

@Suite("Game store")
struct GameStoreTests {
    private let players = [PlayerID("first"), PlayerID("second")]

    private func started(rule: EndGameRule = .immediate) throws -> GameState {
        let configuration = try GameConfiguration(
            playerIDs: players,
            seed: 42,
            firstPlayer: .fixed(players[0]),
            rules: GameRules(specialCardCatalog: .standard, endGameRule: rule)
        )
        var state = try GameState(configuration: configuration)
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            (state, _) = try GameEngine.apply(.draftCube(good: good, ship: ship), by: players[seat], to: state)
        }
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        return state
    }

    @Test func publishesSuccessfulUpdatesInOrderAndFinishesAtGameEnd() async throws {
        let store = GameStore(initialState: try started())
        let updates = await store.updates()

        try await store.send(.passPlanning, by: players[0])
        try await store.send(.drawCards, by: players[0])

        var received: [GameUpdate] = []
        for await update in updates {
            received.append(update)
        }

        #expect(received.count == 2)
        #expect(received[0].events == [.planningPassed(player: players[0])])
        #expect(received[0].newState.ending.status == .ongoing)
        #expect(received[1].events.contains(.deckEmptied))
        #expect(received[1].events.contains(.gameEnded(winners: players)))
        #expect(received[1].newState.ending.status == .finished)
        #expect(await store.activeSubscriberCount == 0)

        let lateSubscription = await store.updates()
        var lateUpdates: [GameUpdate] = []
        for await update in lateSubscription {
            lateUpdates.append(update)
        }
        #expect(lateUpdates.isEmpty)
    }

    @Test func rejectionDoesNotChangeStateOrPublishAnUpdate() async throws {
        let initial = try started()
        let store = GameStore(initialState: initial)
        let updates = await store.updates()

        do {
            try await store.send(.drawCards, by: players[0])
            Issue.record("Expected an action rejection")
        } catch {
            #expect(error.error == .turnFlow(.wrongPhase))
        }

        try await store.send(.passPlanning, by: players[0])
        try await store.send(.drawCards, by: players[0])

        var received: [GameUpdate] = []
        for await update in updates {
            received.append(update)
        }

        let (expectedAfterPass, expectedEvents) = try GameEngine.apply(
            .passPlanning, by: players[0], to: initial
        )
        #expect(received.count == 2)
        #expect(received[0] == GameUpdate(newState: expectedAfterPass, events: expectedEvents))
        #expect(received[0].events.allSatisfy { $0 != .cardsDrawn(player: players[0], count: 1) })
    }

    @Test func concurrentDuplicateSubmissionsCommitOnlyOnce() async throws {
        let store = GameStore(initialState: try started())
        let updates = await store.updates()

        let successes = await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for _ in 0..<2 {
                group.addTask {
                    do {
                        try await store.send(.passPlanning, by: self.players[0])
                        return true
                    } catch {
                        return false
                    }
                }
            }
            var count = 0
            for await succeeded in group where succeeded {
                count += 1
            }
            return count
        }
        #expect(successes == 1)

        try await store.send(.drawCards, by: players[0])
        var received: [GameUpdate] = []
        for await update in updates {
            received.append(update)
        }

        #expect(received.count == 2)
        #expect(received[0].events == [.planningPassed(player: players[0])])
        #expect(received[1].events.contains(.gameEnded(winners: players)))
    }

    @Test func cancellingAConsumerRemovesItsSubscription() async throws {
        let store = GameStore(initialState: try started())
        let updates = await store.updates()
        #expect(await store.activeSubscriberCount == 1)

        let (startedStream, startedContinuation) = AsyncStream<Void>.makeStream()
        let consumer = Task {
            var iterator = updates.makeAsyncIterator()
            startedContinuation.yield(())
            _ = await iterator.next()
        }
        var startedIterator = startedStream.makeAsyncIterator()
        _ = await startedIterator.next()
        startedContinuation.finish()

        consumer.cancel()
        await consumer.value
        for _ in 0..<100 where await store.activeSubscriberCount != 0 {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        #expect(await store.activeSubscriberCount == 0)
    }
}
