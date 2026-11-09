import Foundation
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

    @Test(arguments: SpecialCardKind.allCases)
    func EC12PurchasePriceBoundariesAreAtomic(kind: SpecialCardKind) throws {
        let price = GameRules.standard.specialCardCatalog.entry(for: kind).price
        let goods: [GoodType] = kind == .ship ? [.silk] : kind == .largeShip ? [.silk, .tea] : []
        let action = GameAction.buySpecialCard(kind: kind, loadCubes: goods)
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: price - 1, players[1]: 0])
        let before = state
        #expect(throws: ActionRejection(
            error: .banking(.coin(player: .insufficientFunds(required: price, available: price - 1))),
            action: action, player: players[0]
        )) {
            try GameEngine.apply(action, by: players[0], to: state)
        }
        #expect(state == before)
        #expect(!(try state.legalActions(for: players[0])).contains(action))
        state.bank = try Bank(restoring: [players[0]: price, players[1]: 0])
        #expect(try state.legalActions(for: players[0]).contains(action))
        let (purchased, events) = try GameEngine.apply(action, by: players[0], to: state)
        #expect(try purchased.bank.balance(of: players[0]).available == 0)
        #expect(purchased.tableaux[0].count(of: kind) == 1)
        #expect(events == [.specialCardBought(player: players[0], kind: kind, loadCubes: goods)])
    }

    @Test(arguments: [[GoodType.silk], [.silk, .tea]])
    func EC30LargeShipPurchaseRestoresAndCanExchangeItsCargo(goods: [GoodType]) throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 30, players[1]: 0])
        let purchase = GameAction.buySpecialCard(kind: .largeShip, loadCubes: goods)
        #expect(try state.legalActions(for: players[0]).contains(purchase))
        (state, _) = try GameEngine.apply(purchase, by: players[0], to: state)
        #expect(state.fleets[0].ships[2].cubes.map(\.good) == goods)
        #expect(state.turn?.status == .active(.trading))
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(restored == state)
        (state, _) = try GameEngine.apply(.drawCards, by: players[0], to: restored)
        (state, _) = try GameEngine.apply(.passPlanning, by: players[1], to: state)
        (state, _) = try GameEngine.apply(.drawCards, by: players[1], to: state)
        let exchange = GameAction.exchangeCube(ship: 2, cubeIndex: goods.count - 1, good: .indigo)
        #expect(try state.legalActions(for: players[0]).contains(exchange))
        let (next, events) = try GameEngine.apply(exchange, by: players[0], to: state)
        #expect(next.fleets[0].ships[2].cubes.count == goods.count)
        #expect(next.fleets[0].ships[2].cubes.last?.good == .indigo)
        #expect(events == [.cubeExchanged(player: players[0], ship: 2, cubeIndex: goods.count - 1, good: .indigo)])
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(next)) == next)
    }

    @Test func EC30RejectsEmptyAndOverloadedLargeShipsAndEmptySavedShips() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 30, players[1]: 0])
        for goods: [GoodType] in [[], [.tea, .silk, .sugar]] {
            let action = GameAction.buySpecialCard(kind: .largeShip, loadCubes: goods)
            let before = state
            #expect(throws: ActionRejection(error: .planning(.invalidShipLoad), action: action, player: players[0])) {
                try GameEngine.apply(action, by: players[0], to: state)
            }
            #expect(state == before)
            #expect(!(try state.legalActions(for: players[0])).contains(action))
        }
        try state.stock.purchase(.largeShip, for: &state.tableaux[0])
        state.fleets[0].addShip(kind: .large)
        #expect(throws: GameStateError.shipNotFull) {
            try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        }
    }

    @Test func EC13EC15EC28DeliveryPaysAllPlayersAfterSameColourCover() throws {
        var state = try started()
        try state.stock.purchase(.tradeAgreement, for: &state.tableaux[0])
        try state.stock.purchase(.tradeAgreement, for: &state.tableaux[0])
        var hand = Hand()
        try hand.add(Array(repeating: GoodsCard(good: .sugar), count: 2), limit: 6)
        state.hands[0] = hand
        state.marketplace = try Marketplace(visibleCards: [
            GoodsCard(good: .sugar), GoodsCard(good: .tea), GoodsCard(good: .tea),
            GoodsCard(good: .tea), GoodsCard(good: .tea), GoodsCard(good: .tea)
        ])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let placements = [0, 1].map { DeliveryPlacement(slot: $0, card: GoodsCard(good: .sugar)) }
        let (next, events) = try GameEngine.apply(.deliverCards(placements), by: players[0], to: state)
        #expect(next.marketplace.demand(for: .sugar) == 2)
        #expect(events == [
            .cardsDelivered(player: players[0], placements: placements),
            .coinsEarned(player: players[0], amount: 2, reason: .deliveryPayout(.sugar)),
            .coinsEarned(player: players[1], amount: 2, reason: .deliveryPayout(.sugar)),
            .turnEnded(player: players[0])
        ])
        var secondHand = Hand()
        try secondHand.add([GoodsCard(good: .sugar)], limit: 6)
        var secondTurn = next
        secondTurn.hands[1] = secondHand
        (secondTurn, _) = try GameEngine.apply(.passPlanning, by: players[1], to: secondTurn)
        let otherDelivery = [DeliveryPlacement(slot: 2, card: GoodsCard(good: .sugar))]
        let (scored, otherEvents) = try GameEngine.apply(
            .deliverCards(otherDelivery), by: players[1], to: secondTurn
        )
        #expect(otherEvents == [
            .cardsDelivered(player: players[1], placements: otherDelivery),
            .coinsEarned(player: players[0], amount: 3, reason: .deliveryPayout(.sugar)),
            .coinsEarned(player: players[0], amount: 4, reason: .tradeAgreementBonus),
            .coinsEarned(player: players[1], amount: 3, reason: .deliveryPayout(.sugar)),
            .turnEnded(player: players[1])
        ])
        #expect(try scored.bank.balance(of: players[0]).available == 9)
        #expect(try scored.bank.balance(of: players[1]).available == 5)
    }

    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn],
          [(0, false), (0, true), (1, false), (1, true), (2, false), (2, true)])
    func EC23EC24EC36EndGameFromEverySeat(
        rule: EndGameRule, scenario: (offset: Int, officeEmptiesDeck: Bool)
    ) throws {
        let seated = [PlayerID("a"), PlayerID("b"), PlayerID("c")]
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(
            playerIDs: seated, seed: 42, firstPlayer: .fixed(seated[1]), rules: rules
        )
        var state = try GameState(configuration: configuration)
        while state.turn == nil {
            let seat = try state.draft.nextSeat()
            let action = try #require(state.legalActions(for: seated[seat]).first)
            (state, _) = try GameEngine.apply(action, by: seated[seat], to: state)
        }
        for _ in 0..<scenario.offset {
            let seat = try #require(state.turn?.currentSeat)
            (state, _) = try GameEngine.apply(.passPlanning, by: seated[seat], to: state)
            (state, _) = try GameEngine.apply(.drawCards, by: seated[seat], to: state)
        }
        let triggeringSeat = try #require(state.turn?.currentSeat)
        if scenario.officeEmptiesDeck {
            try state.stock.purchase(.office, for: &state.tableaux[triggeringSeat])
        }
        state.bank = try Bank(restoring: [seated[0]: 5, seated[1]: 3, seated[2]: 5])
        state.deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .tea), count: scenario.officeEmptiesDeck ? 3 : 1))
        (state, _) = try GameEngine.apply(.passPlanning, by: seated[triggeringSeat], to: state)
        var events: [GameEvent]
        (state, events) = try GameEngine.apply(.drawCards, by: seated[triggeringSeat], to: state)
        #expect(events.contains(.deckEmptied))
        #expect(events.contains(.officeExtrasDrawn(player: seated[triggeringSeat], count: 1)) == scenario.officeEmptiesDeck)
        if rule == .oneMoreTurn && scenario.offset < 2 {
            #expect(state.ending.status != .finished)
            while state.ending.status != .finished {
                let seat = try #require(state.turn?.currentSeat)
                (state, _) = try GameEngine.apply(.passPlanning, by: seated[seat], to: state)
                let legal = try state.legalActions(for: seated[seat])
                #expect(!legal.contains(.drawCards))
                #expect(legal.contains(.skipTrading))
                (state, events) = try GameEngine.apply(.skipTrading, by: seated[seat], to: state)
                #expect(!events.contains { if case .officeExtrasDrawn = $0 { return true }; return false })
            }
        }
        #expect(state.ending.status == .finished)
        #expect(events.contains(.gameEnded(winners: [seated[0], seated[2]])))
        #expect(try state.ending.standings(players: seated, bank: state.bank).entries.map(\.player) == seated)
        for action: GameAction in [.passPlanning, .drawCards, .skipTrading] {
            #expect(throws: ActionRejection(
                error: .gameEnding(.alreadyEnded), action: action, player: seated[triggeringSeat]
            )) {
                try GameEngine.apply(action, by: seated[triggeringSeat], to: state)
            }
        }
    }
}
