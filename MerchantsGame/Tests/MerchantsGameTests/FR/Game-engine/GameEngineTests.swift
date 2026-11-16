import Testing
@testable import MerchantsGame

@Suite("Game engine")
struct GameEngineTests {
    private let players = [PlayerID("first"), PlayerID("second")]

    private func started(rule: EndGameRule = .oneMoreTurn) throws -> GameState {
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(playerIDs: players, seed: 42, firstPlayer: .fixed(players[0]), rules: rules)
        var state = try GameState(configuration: configuration)
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            let (next, events) = try GameEngine.apply(.draftCube(good: good, ship: ship), by: players[seat], to: state)
            #expect(events == [.cubeDrafted(player: players[seat], good: good, ship: ship)])
            state = next
        }
        return state
    }

    @Test func setupIsDeterministicAndProjectionContainsOnlyOwnHand() throws {
        let state = try started()
        #expect(try started() == state)
        let view = try state.playerView(for: players[0])
        #expect(view.hand == state.hands[0].contents)
        #expect(view.handCounts == [3, 3])
        #expect(view.deckCount == 48)
        #expect(view.marketplaceCards == state.marketplace.visibleCards)
        #expect(view.draft == nil)
        #expect(throws: EngineError.unknownPlayer) { try state.playerView(for: PlayerID("unknown")) }
    }

    @Test func rejectedActionsAreAtomicAndLegalActionsUseEngineValidation() throws {
        let initial = try started()
        let bad = GameAction.drawCards
        do {
            _ = try GameEngine.apply(bad, by: players[0], to: initial)
            Issue.record("Expected a phase rejection")
        } catch {
            #expect(error.action == bad)
            #expect(error.player == players[0])
            #expect(error.error == .turnFlow(.wrongPhase))
        }
        #expect(initial.turn?.currentSeat == 0)
        let actions = try initial.legalActions(for: players[0])
        #expect(actions.contains(.passPlanning))
        #expect(!actions.contains(.drawCards))
        #expect(try initial.legalActions(for: players[1]).isEmpty)
        for action in actions {
            let (next, events) = try GameEngine.apply(action, by: players[0], to: initial)
            #expect(!events.isEmpty)
            #expect(next != initial)
        }
    }

    @Test func deliveryScoresAndFailureDoesNotMutateInput() throws {
        var state = try started()
        var hand = Hand()
        try hand.add([GoodsCard(good: .sugar)], limit: 6)
        state.hands[0] = hand
        state.marketplace = try Marketplace(visibleCards: Array(repeating: GoodsCard(good: .tea), count: 6))
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let snapshot = state
        let invalid = GameAction.deliverCards([DeliveryPlacement(slot: 0, card: GoodsCard(good: .tea))])
        #expect(throws: ActionRejection.self) { try GameEngine.apply(invalid, by: players[0], to: state) }
        #expect(state == snapshot)
        let (next, events) = try GameEngine.apply(
            .deliverCards([DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar))]), by: players[0], to: state
        )
        #expect(next.hands[0].count == 0)
        #expect(try next.bank.balance(of: players[0]).available == 1)
        #expect(try next.bank.balance(of: players[1]).available == 1)
        #expect(events.contains(.coinsEarned(player: players[1], amount: 1, reason: .deliveryPayout(.sugar))))
        #expect(events.contains(.turnEnded(player: players[0])))
    }

    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func deckEmptyTriggersCorrectEndAndRejectsActionsAfterwards(rule: EndGameRule) throws {
        var state = try started(rule: rule)
        state.deck = DrawDeck(cards: [GoodsCard(good: .tea)])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        var events: [GameEvent]
        (state, events) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        #expect(events.contains(.deckEmptied))
        if rule == .oneMoreTurn {
            #expect(events.contains(.finalRoundBegan(endsAfter: players[1])))
            #expect(state.ending.status == .finalRound(nextSeat: 1))
            (state, _) = try GameEngine.apply(.passPlanning, by: players[1], to: state)
            (state, events) = try GameEngine.apply(.skipTrading, by: players[1], to: state)
            #expect(events.contains(.turnEnded(player: players[1])))
        } else {
            #expect(!events.contains(.turnEnded(player: players[0])))
        }
        #expect(state.ending.status == .finished)
        #expect(events.contains(.gameEnded(winners: players)))
        #expect(try state.legalActions(for: players[0]).isEmpty)
        do {
            _ = try GameEngine.apply(.passPlanning, by: players[0], to: state)
            Issue.record("Expected finished-game rejection")
        } catch {
            #expect(error.error == .gameEnding(.alreadyEnded))
        }
    }

    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func completeGameUsingLegalActions(rule: EndGameRule) throws {
        var state = try started(rule: rule)
        var turns = 0
        while state.ending.status != .finished && turns < 110 {
            let seat = try #require(state.turn?.currentSeat)
            let player = players[seat]
            let planning = try state.legalActions(for: player)
            #expect(planning.contains(.passPlanning))
            (state, _) = try GameEngine.apply(.passPlanning, by: player, to: state)
            let choices = try state.legalActions(for: player)
            let action: GameAction
            if choices.contains(.drawCards) {
                action = .drawCards
            } else if let delivery = choices.first(where: {
                if case .deliverCards = $0 { return true }
                return false
            }) {
                action = delivery
            } else {
                action = try #require(choices.first)
            }
            let (next, events) = try GameEngine.apply(action, by: player, to: state)
            #expect(!events.isEmpty)
            state = next
            turns += 1
        }
        #expect(state.ending.status == .finished)
        #expect(turns < 110)
    }

    @Test func officeDrawEmitsExtraEventAndTriggersEnding() throws {
        var state = try started()
        try state.stock.purchase(.office, for: &state.tableaux[0])
        state.deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .tea), count: 3))
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let (next, events) = try GameEngine.apply(.drawCards, by: players[0], to: state)
        #expect(events.contains(.cardsDrawn(player: players[0], count: 2)))
        #expect(events.contains(.officeExtrasDrawn(player: players[0], count: 1)))
        #expect(events.contains(.deckEmptied))
        #expect(next.ending.status == .finalRound(nextSeat: 1))
    }

    @Test func failedPayoutAndFailedPurchaseAreAtomic() throws {
        var state = try started()
        let purchase = GameAction.buySpecialCard(kind: .office, loadCubes: [])
        let original = state
        #expect(throws: ActionRejection.self) { try GameEngine.apply(purchase, by: players[0], to: state) }
        #expect(state == original)
        var hand = Hand()
        try hand.add([GoodsCard(good: .sugar)], limit: 6)
        state.hands[0] = hand
        state.marketplace = try Marketplace(visibleCards: Array(repeating: GoodsCard(good: .tea), count: 6))
        state.bank = try Bank(restoring: [players[0]: 5_000, players[1]: 0])
        (state, _) = try GameEngine.apply(.passPlanning, by: players[0], to: state)
        let snapshot = state
        let delivery = GameAction.deliverCards([DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar))])
        do {
            _ = try GameEngine.apply(delivery, by: players[0], to: state)
            Issue.record("Expected balance limit rejection")
        } catch {
            #expect(error.error == .banking(.coin(player: .limitExceeded(limit: 5_000, attempted: 5_001))))
        }
        #expect(state == snapshot)
        #expect(!(try state.legalActions(for: players[0])).contains(delivery))
    }

    @Test func completeFinalRoundsGiveEverySeatEqualTurns() throws {
        for count in 2...4 {
            let ids = (0..<count).map { PlayerID("p\($0)") }
            let configuration = try GameConfiguration(playerIDs: ids, seed: UInt64(count),
                                                      firstPlayer: .fixed(ids[count - 1]))
            var state = try GameState(configuration: configuration)
            while state.turn == nil {
                let seat = try state.draft.nextSeat()
                let legal = try state.legalActions(for: ids[seat])
                (state, _) = try GameEngine.apply(try #require(legal.first), by: ids[seat], to: state)
            }
            var completed = Array(repeating: 0, count: count)
            var turns = 0
            while state.ending.status != .finished && turns < 110 {
                let seat = try #require(state.turn?.currentSeat)
                let player = ids[seat]
                (state, _) = try GameEngine.apply(.passPlanning, by: player, to: state)
                let actions = try state.legalActions(for: player)
                let selected = actions.contains(.drawCards) ? GameAction.drawCards : try #require(actions.first)
                let result = try GameEngine.apply(selected, by: player, to: state)
                #expect(result.1.contains(.turnEnded(player: player)))
                state = result.0
                completed[seat] += 1
                turns += 1
            }
            #expect(state.ending.status == .finished)
            #expect(turns < 110)
            #expect(Set(completed).count == 1)
        }
    }
}
