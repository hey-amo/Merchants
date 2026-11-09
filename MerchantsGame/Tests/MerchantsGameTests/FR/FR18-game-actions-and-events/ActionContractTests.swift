import Foundation
import Testing
@testable import MerchantsGame

@Suite("Action and event contract")
struct ActionContractTests {
    private let players = [PlayerID("first"), PlayerID("second")]

    private func initial() throws -> GameState {
        try GameState(configuration: GameConfiguration(
            playerIDs: players, seed: 42, firstPlayer: .fixed(players[0]),
            rules: GameRules(specialCardCatalog: .standard, endGameRule: .immediate)
        ))
    }

    private func started() throws -> GameState {
        var state = try initial()
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            (state, _) = try GameEngine.apply(.draftCube(good: good, ship: ship), by: players[seat], to: state)
        }
        return state
    }

    private func assertRejection(
        _ action: GameAction, player: PlayerID, error: EngineError, state: GameState
    ) throws {
        let before = state
        #expect(throws: ActionRejection(error: error, action: action, player: player)) {
            try GameEngine.apply(action, by: player, to: state)
        }
        #expect(state == before)
        #expect(!(try state.legalActions(for: player)).contains(action))
    }

    @Test func eachActionRejectsWithContextAndPreservesState() throws {
        let draft = try initial()
        try assertRejection(.draftCube(good: .tea, ship: 0), player: players[0],
                            error: .draft(.notDraftingSeat), state: draft)
        try assertRejection(.draftCube(good: .tea, ship: 9), player: players[1],
                            error: .draft(.ship(.shipNotFound)), state: draft)
        let (onePick, _) = try GameEngine.apply(.draftCube(good: .tea, ship: 0), by: players[1], to: draft)
        let (twoPicks, _) = try GameEngine.apply(.draftCube(good: .sugar, ship: 0), by: players[0], to: onePick)
        try assertRejection(.draftCube(good: .tea, ship: 0), player: players[0],
                            error: .draft(.shipNotEmpty), state: twoPicks)

        let planning = try started()
        try assertRejection(.draftCube(good: .tea, ship: 0), player: players[0],
                            error: .invalidAction, state: planning)
        try assertRejection(.exchangeCube(ship: 0, cubeIndex: 0, good: .sugar), player: players[0],
                            error: .ships(.sameGood), state: planning)
        try assertRejection(.buySpecialCard(kind: .office, loadCubes: []), player: players[0],
                            error: .banking(.coin(player: .insufficientFunds(required: 8, available: 0))),
                            state: planning)
        try assertRejection(.endPlanning, player: players[0],
                            error: .turnFlow(.baseActionRequired), state: planning)
        try assertRejection(.passPlanning, player: players[1], error: .turnFlow(.notYourTurn), state: planning)
        try assertRejection(.drawCards, player: players[0], error: .turnFlow(.wrongPhase), state: planning)
        try assertRejection(.deliverCards([]), player: players[0], error: .turnFlow(.wrongPhase), state: planning)
        try assertRejection(.skipTrading, player: players[0], error: .turnFlow(.wrongPhase), state: planning)

        let (trading, _) = try GameEngine.apply(.passPlanning, by: players[0], to: planning)
        try assertRejection(.passPlanning, player: players[0], error: .turnFlow(.wrongPhase), state: trading)
        try assertRejection(.exchangeCube(ship: 0, cubeIndex: 0, good: .tea), player: players[0],
                            error: .turnFlow(.wrongPhase), state: trading)
        try assertRejection(.buySpecialCard(kind: .office, loadCubes: []), player: players[0],
                            error: .turnFlow(.wrongPhase), state: trading)
        try assertRejection(.endPlanning, player: players[0], error: .turnFlow(.wrongPhase), state: trading)
        try assertRejection(.skipTrading, player: players[0],
                            error: .turnFlow(.skipOnlyWhenDeckEmpty), state: trading)
        try assertRejection(.deliverCards([]), player: players[0],
                            error: .marketplace(.emptyDelivery), state: trading)
        let good = try #require(trading.hands[0].contents.first?.good)
        let duplicate = [DeliveryPlacement(slot: 0, source: .hand(good)), DeliveryPlacement(slot: 0, source: .hand(good))]
        try assertRejection(.deliverCards(duplicate), player: players[0],
                            error: .marketplace(.duplicateSlot), state: trading)
    }

    @Test func eachActionRejectsUnknownPlayersAndFinishedGames() throws {
        var state = try started()
        let actions: [GameAction] = [
            .draftCube(good: .tea, ship: 0), .exchangeCube(ship: 0, cubeIndex: 0, good: .tea),
            .buySpecialCard(kind: .office, loadCubes: []), .passPlanning, .endPlanning,
            .deliverCards([DeliveryPlacement(slot: 0, source: .hand(.tea))]), .drawCards, .skipTrading
        ]
        let unknown = PlayerID("unknown")
        for action in actions {
            try assertRejection(action, player: unknown, error: .unknownPlayer, state: state)
        }
        for action in actions.dropFirst() {
            try assertRejection(action, player: players[1], error: .turnFlow(.notYourTurn), state: state)
        }
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        (state, _) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        for action in actions {
            try assertRejection(action, player: players[0], error: .gameEnding(.alreadyEnded), state: state)
        }
    }

    @Test func EC8EC9EC12PlanningRejectionsKeepActionContext() throws {
        var planning = try started()
        planning.bank = try Bank(restoring: [players[0]: 30, players[1]: 0])
        try assertRejection(.exchangeCube(ship: 9, cubeIndex: 0, good: .silk), player: players[0],
                            error: .ships(.shipNotFound), state: planning)
        try assertRejection(.exchangeCube(ship: 0, cubeIndex: 2, good: .silk), player: players[0],
                            error: .ships(.cubeIndexOutOfRange), state: planning)
        try assertRejection(.buySpecialCard(kind: .largeShip, loadCubes: []), player: players[0],
                            error: .planning(.invalidShipLoad), state: planning)

        var exhausted = planning
        while exhausted.supply.available(of: .silk) > 0 { _ = try exhausted.supply.take(.silk) }
        try assertRejection(.exchangeCube(ship: 0, cubeIndex: 0, good: .silk), player: players[0],
                            error: .cubeSupply(.noneAvailable(.silk)), state: exhausted)
        try assertRejection(.buySpecialCard(kind: .ship, loadCubes: [.silk]), player: players[0],
                            error: .cubeSupply(.noneAvailable(.silk)), state: exhausted)

        var soldOut = planning
        try soldOut.stock.purchase(.office, for: &soldOut.tableaux[1])
        try soldOut.stock.purchase(.office, for: &soldOut.tableaux[1])
        try assertRejection(.buySpecialCard(kind: .office, loadCubes: []), player: players[0],
                            error: .specialCards(.outOfStock(.office)), state: soldOut)
        var owned = planning
        try owned.stock.purchase(.customsHouse, for: &owned.tableaux[0])
        try assertRejection(.buySpecialCard(kind: .customsHouse, loadCubes: []), player: players[0],
                            error: .specialCards(.ownershipLimitReached(.customsHouse)), state: owned)

        try planning.stock.purchase(.crane, for: &planning.tableaux[0])
        let (exchanged, _) = try GameEngine.apply(
            .exchangeCube(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: planning
        )
        try assertRejection(.exchangeCube(ship: 0, cubeIndex: 0, good: .tea), player: players[0],
                            error: .turnFlow(.shipAlreadyExchangedThisPhase), state: exchanged)
        try assertRejection(.passPlanning, player: players[0],
                            error: .turnFlow(.baseActionAlreadyTaken), state: exchanged)
        try assertRejection(.buySpecialCard(kind: .office, loadCubes: []), player: players[0],
                            error: .turnFlow(.baseActionAlreadyTaken), state: exchanged)
    }

    @Test func EC1EC2TradingRejectionsKeepActionContext() throws {
        var state = try started()
        var hand = Hand()
        try hand.add(Array(repeating: GoodsCard(good: .sugar), count: 5), limit: 6)
        state.hands[0] = hand
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        try assertRejection(.drawCards, player: players[0], error: .turnFlow(.cannotDrawMustDeliver), state: state)
        let sugar = DeliveryPlacement(slot: 0, source: .hand(.sugar))
        try assertRejection(.deliverCards([sugar, DeliveryPlacement(slot: 1, source: .hand(.tea))]),
                            player: players[0], error: .marketplace(.mixedGoods), state: state)
        try assertRejection(.deliverCards([DeliveryPlacement(slot: 6, source: .hand(.sugar))]),
                            player: players[0], error: .marketplace(.slotOutOfRange), state: state)
        let seven = (0..<7).map { DeliveryPlacement(slot: $0, source: .hand(.sugar)) }
        try assertRejection(.deliverCards(seven), player: players[0], error: .marketplace(.tooManyCards), state: state)
        try assertRejection(.deliverCards([DeliveryPlacement(slot: 0, source: .hand(.tea))]),
                            player: players[0],
                            error: .hand(.insufficientCards(good: .tea, required: 1, available: 0)), state: state)
    }

    @Test func handSourcePreservesExistingPlacementEncoding() throws {
        let placement = DeliveryPlacement(slot: 1, source: .hand(.tea))
        #expect(placement == DeliveryPlacement(slot: 1, card: GoodsCard(good: .tea)))
        #expect(placement.source == .hand(.tea))
        let encoded = try JSONEncoder().encode(placement)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json["card"] != nil)
        #expect(json["source"] == nil)
        #expect(try JSONDecoder().decode(DeliveryPlacement.self, from: encoded).source == .hand(.tea))
        let legacy = Data(#"{"slot":1,"card":{"good":{"tea":{}}}}"#.utf8)
        #expect(try JSONDecoder().decode(DeliveryPlacement.self, from: legacy) == placement)
        let action = GameAction.deliverCards([placement])
        #expect(try JSONDecoder().decode(GameAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test func EC16DeliveryWithoutMatchingCubesPaysNobody() throws {
        let planning = try started()
        let (trading, _) = try GameEngine.apply(.passPlanning, by: players[0], to: planning)
        let good = try #require(trading.hands[0].contents.first {
            card in trading.fleets.allSatisfy { $0.cubeCount(of: card.good) == 0 }
        }?.good)
        let placements = [DeliveryPlacement(slot: 0, source: .hand(good))]
        let (delivered, events) = try GameEngine.apply(.deliverCards(placements), by: players[0], to: trading)
        #expect(delivered.bank == trading.bank)
        #expect(events == [.cardsDelivered(player: players[0], placements: placements),
                           .turnEnded(player: players[0])])
    }

    @Test func drawEventsRevealOnlyPlayerAndCardCount() throws {
        for event in [GameEvent.cardsDrawn(player: players[0], count: 2),
                      .officeExtrasDrawn(player: players[0], count: 1)] {
            let object = try #require(
                JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: [String: Any]]
            )
            let payload = try #require(object.values.first)
            #expect(Set(payload.keys) == Set(["player", "count"]))
            #expect(payload["count"] as? Int == (event == .cardsDrawn(player: players[0], count: 2) ? 2 : 1))
            #expect(try JSONDecoder().decode(GameEvent.self, from: JSONEncoder().encode(event)) == event)
        }
    }

    @Test func eachSuccessfulActionReportsItsEvents() throws {
        let draft = try initial()
        let (_, draftEvents) = try GameEngine.apply(.draftCube(good: .tea, ship: 0), by: players[1], to: draft)
        #expect(draftEvents == [.cubeDrafted(player: players[1], good: .tea, ship: 0)])

        var planning = try started()
        planning.bank = try Bank(restoring: [players[0]: 12, players[1]: 0])
        let (_, exchangeEvents) = try GameEngine.apply(
            .exchangeCube(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: planning
        )
        #expect(exchangeEvents == [.cubeExchanged(player: players[0], ship: 0, cubeIndex: 0, good: .silk)])
        let (bought, buyEvents) = try GameEngine.apply(
            .buySpecialCard(kind: .crane, loadCubes: []), by: players[0], to: planning
        )
        #expect(buyEvents == [.specialCardBought(player: players[0], kind: .crane, loadCubes: [])])
        let (_, endEvents) = try GameEngine.apply(.endPlanning, by: players[0], to: bought)
        #expect(endEvents == [.planningEnded(player: players[0])])
        let (trading, passEvents) = try GameEngine.apply(.passPlanning, by: players[0], to: planning)
        #expect(passEvents == [.planningPassed(player: players[0])])
        let (_, drawEvents) = try GameEngine.apply(.drawCards, by: players[0], to: trading)
        #expect(drawEvents == [.cardsDrawn(player: players[0], count: 2), .turnEnded(player: players[0])])

        let good = try #require(trading.hands[0].contents.first?.good)
        let placements = [DeliveryPlacement(slot: 0, source: .hand(good))]
        let (delivered, deliveryEvents) = try GameEngine.apply(.deliverCards(placements), by: players[0], to: trading)
        let payout = try DeliveryScoring.transactions(
            for: good, marketplace: delivered.marketplace, players: players, fleets: delivered.fleets,
            tableaux: delivered.tableaux, rules: delivered.configuration.rules
        )
        #expect(deliveryEvents == [.cardsDelivered(player: players[0], placements: placements)]
            + payout.map { .coinsEarned(player: $0.player, amount: $0.amount, reason: $0.reason) }
            + [.turnEnded(player: players[0])])

        var continuing = try GameState(configuration: GameConfiguration(
            playerIDs: players, seed: 42, firstPlayer: .fixed(players[0])
        ))
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            (continuing, _) = try GameEngine.apply(.draftCube(good: good, ship: ship), by: players[seat], to: continuing)
        }
        continuing.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        (continuing, _) = try GameEngine.apply(.passPlanning, by: players[0], to: continuing)
        (continuing, _) = try GameEngine.apply(.drawCards, by: players[0], to: continuing)
        (continuing, _) = try GameEngine.apply(.passPlanning, by: players[1], to: continuing)
        let (_, skipEvents) = try GameEngine.apply(.skipTrading, by: players[1], to: continuing)
        #expect(skipEvents == [.tradingSkipped(player: players[1]), .turnEnded(player: players[1]),
                               .gameEnded(winners: players)])
    }

    @Test func rejectedActionsPublishNothingAndSuccessfulEventsRemainOrdered() async throws {
        var state = try started()
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        let store = GameStore(initialState: state)
        let updates = await store.updates()
        let rejected: [(GameAction, EngineError)] = [
            (.draftCube(good: .tea, ship: 0), .invalidAction),
            (.exchangeCube(ship: 0, cubeIndex: 0, good: .sugar), .ships(.sameGood)),
            (.buySpecialCard(kind: .office, loadCubes: []),
             .banking(.coin(player: .insufficientFunds(required: 8, available: 0)))),
            (.passPlanning, .turnFlow(.notYourTurn)),
            (.endPlanning, .turnFlow(.baseActionRequired)),
            (.deliverCards([]), .turnFlow(.wrongPhase)),
            (.drawCards, .turnFlow(.wrongPhase)),
            (.skipTrading, .turnFlow(.wrongPhase))
        ]
        for (action, expected) in rejected {
            let player = action == .passPlanning ? players[1] : players[0]
            do {
                try await store.send(action, by: player)
                Issue.record("Expected rejection for \(action)")
            } catch {
                #expect(error == ActionRejection(error: expected, action: action, player: player))
            }
            #expect(await store.snapshot() == state)
        }
        try await store.send(.passPlanning, by: players[0])
        let afterPass = await store.snapshot()
        for (action, expected) in [(GameAction.skipTrading, EngineError.turnFlow(.skipOnlyWhenDeckEmpty)),
                                   (.deliverCards([]), .marketplace(.emptyDelivery))] {
            do {
                try await store.send(action, by: players[0])
                Issue.record("Expected rejection for \(action)")
            } catch {
                #expect(error == ActionRejection(error: expected, action: action, player: players[0]))
            }
            #expect(await store.snapshot() == afterPass)
        }
        try await store.send(.drawCards, by: players[0])
        var received: [GameUpdate] = []
        for await update in updates { received.append(update) }
        let (expectedAfterPass, passEvents) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let (finished, drawEvents) = try GameEngine.apply(.drawCards, by: players[0], to: expectedAfterPass)
        #expect(afterPass == expectedAfterPass)
        #expect(received == [GameUpdate(newState: expectedAfterPass, events: passEvents),
                             GameUpdate(newState: finished, events: drawEvents)])
    }
}
