import Testing
@testable import MerchantsGame

@Suite("Core gameplay acceptance")
struct CoreGameplayAcceptanceTests {
    private let players = [PlayerID("first"), PlayerID("second")]

    private func started(rule: EndGameRule = .oneMoreTurn) throws -> GameState {
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(
            playerIDs: players, seed: 42, firstPlayer: .fixed(players[0]), rules: rules
        )
        var state = try GameState(configuration: configuration)
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            let (next, events) = try GameEngine.apply(
                .draftCube(good: good, ship: ship), by: players[seat], to: state
            )
            #expect(events == [.cubeDrafted(player: players[seat], good: good, ship: ship)])
            state = next
        }
        return state
    }

    @Test func planningEventsAndOptionalCraneExchange() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 12, players[1]: 0])
        let snapshot = state
        let (bought, events) = try GameEngine.apply(
            .buySpecialCard(kind: .crane, loadCubes: []), by: players[0], to: state
        )
        #expect(state == snapshot)
        #expect(events == [.specialCardBought(player: players[0], kind: .crane, loadCubes: [])])
        #expect(try bought.bank.balance(of: players[0]).available == 0)
        let (ended, endEvents) = try GameEngine.apply(.endPlanning, by: players[0], to: bought)
        #expect(endEvents == [.planningEnded(player: players[0])])
        #expect(ended.turn?.status == .active(.trading))

        let (exchanged, exchangeEvents) = try GameEngine.apply(
            .exchangeCube(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: bought
        )
        #expect(exchangeEvents == [.cubeExchanged(player: players[0], ship: 0, cubeIndex: 0, good: .silk)])
        #expect(exchanged.fleets[0].ships[0].cubes[0].good == .silk)
        #expect(exchanged.turn?.status == .active(.trading))
    }

    @Test func deliveryEventsIncludeScoringForBothPlayers() throws {
        var state = try started()
        var hand = Hand()
        try hand.add([GoodsCard(good: .sugar)], limit: 6)
        state.hands[0] = hand
        state.marketplace = try Marketplace(visibleCards: Array(repeating: GoodsCard(good: .tea), count: 6))
        let (trading, planningEvents) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        #expect(planningEvents == [.planningPassed(player: players[0])])
        let placements = [DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar))]
        let (next, events) = try GameEngine.apply(.deliverCards(placements), by: players[0], to: trading)
        #expect(events == [
            .cardsDelivered(player: players[0], placements: placements),
            .coinsEarned(player: players[0], amount: 1, reason: .deliveryPayout(.sugar)),
            .coinsEarned(player: players[1], amount: 1, reason: .deliveryPayout(.sugar)),
            .turnEnded(player: players[0])
        ])
        #expect(try next.bank.balance(of: players[0]).available == 1)
        #expect(try next.bank.balance(of: players[1]).available == 1)
    }

    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func emptyDeckEventsAndFinalRoundSkip(rule: EndGameRule) throws {
        var state = try started(rule: rule)
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let (next, events) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        if rule == .immediate {
            #expect(events == [.cardsDrawn(player: players[0], count: 1), .deckEmptied,
                               .gameEnded(winners: players)])
            #expect(next.ending.status == .finished)
        } else {
            #expect(events == [.cardsDrawn(player: players[0], count: 1), .deckEmptied,
                               .finalRoundBegan(endsAfter: players[1]), .turnEnded(player: players[0])])
            let (trading, _) = try GameEngine.apply(.passPlanning, by: players[1], to: next)
            let (finished, skipEvents) = try GameEngine.apply(.skipTrading, by: players[1], to: trading)
            #expect(skipEvents == [.tradingSkipped(player: players[1]), .turnEnded(player: players[1]),
                                   .gameEnded(winners: players)])
            #expect(finished.ending.status == .finished)
        }
    }

    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func EC6OfficeDrawEmptiesDeckUnderBothRules(rule: EndGameRule) throws {
        var state = try started(rule: rule)
        try state.stock.purchase(.office, for: &state.tableaux[0])
        state.deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .tea), count: 3))
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let (next, events) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        if rule == .immediate {
            #expect(events == [.cardsDrawn(player: players[0], count: 2),
                               .officeExtrasDrawn(player: players[0], count: 1), .deckEmptied,
                               .gameEnded(winners: players)])
            #expect(next.ending.status == .finished)
        } else {
            #expect(events == [.cardsDrawn(player: players[0], count: 2),
                               .officeExtrasDrawn(player: players[0], count: 1), .deckEmptied,
                               .finalRoundBegan(endsAfter: players[1]), .turnEnded(player: players[0])])
            #expect(next.ending.status == .finalRound(nextSeat: 1))
        }
    }

    @Test func EC33CustomsHouseImmediatelyEnablesDraw() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 8, players[1]: 0])
        var hand = Hand()
        try hand.add(Array(repeating: GoodsCard(good: .tea), count: 6), limit: 6)
        state.hands[0] = hand
        let (bought, events) = try GameEngine.apply(
            .buySpecialCard(kind: .customsHouse, loadCubes: []), by: players[0], to: state
        )
        #expect(events == [.specialCardBought(player: players[0], kind: .customsHouse, loadCubes: [])])
        #expect(try bought.legalActions(for: players[0]).contains(.drawCards))
        let (drawn, drawEvents) = try GameEngine.apply(.drawCards, by: players[0], to: bought)
        #expect(drawn.hands[0].count == 8)
        #expect(drawEvents == [.cardsDrawn(player: players[0], count: 2), .turnEnded(player: players[0])])
    }

    @Test func EC34PurchaseDuringFinalRound() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 0, players[1]: 8])
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        (state, _) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        #expect(state.ending.status == .finalRound(nextSeat: 1))
        let action = GameAction.buySpecialCard(kind: .office, loadCubes: [])
        #expect(try state.legalActions(for: players[1]).contains(action))
        let (bought, events) = try GameEngine.apply(action, by: players[1], to: state)
        #expect(events == [.specialCardBought(player: players[1], kind: .office, loadCubes: [])])
        #expect(try bought.bank.balance(of: players[1]).available == 0)
        #expect(bought.tableaux[1].count(of: .office) == 1)
        #expect(!(try bought.legalActions(for: players[1])).contains(.drawCards))
        let (finished, skipEvents) = try GameEngine.apply(.skipTrading, by: players[1], to: bought)
        #expect(skipEvents == [.tradingSkipped(player: players[1]), .turnEnded(player: players[1]),
                               .gameEnded(winners: players)])
        #expect(finished.ending.status == .finished)
    }

    @Test func legalActionsSucceedAndRejectedActionsStayAtomic() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 20, players[1]: 0])
        for _ in 0..<4 {
            let seat = try #require(state.turn?.currentSeat)
            let player = players[seat]
            let snapshot = state
            let legal = try state.legalActions(for: player)
            for action in legal {
                let (_, events) = try GameEngine.apply(action, by: player, to: state)
                #expect(!events.isEmpty)
                #expect(state == snapshot)
            }
            let illegal: GameAction = state.turn?.status == .active(.trading) ? .passPlanning : .drawCards
            #expect(!legal.contains(illegal))
            #expect(throws: ActionRejection.self) { try GameEngine.apply(illegal, by: player, to: state) }
            #expect(state == snapshot)
            let action: GameAction = state.turn?.status == .active(.trading) ? .drawCards : .passPlanning
            (state, _) = try GameEngine.apply(action, by: player, to: state)
        }
    }

    @Test func projectionHidesOpponentsCardsAndDeckOrder() throws {
        let state = try started()
        var changed = state
        var opponent = Hand()
        let replacement: GoodType = state.hands[1].contents.allSatisfy { $0.good == .silk } ? .tea : .silk
        try opponent.add(Array(repeating: GoodsCard(good: replacement), count: 3), limit: 6)
        changed.hands[1] = opponent
        changed.deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .silk), count: state.deck.remaining))
        #expect(changed.hands[1] != state.hands[1])
        let view = try state.playerView(for: players[0])
        let changedView = try changed.playerView(for: players[0])
        #expect(view.hand == state.hands[0].contents)
        #expect(view.handCounts == [3, 3])
        #expect(view.deckCount == state.deck.remaining)
        #expect(view == changedView)
    }
}
