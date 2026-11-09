import Testing
@testable import MerchantsGame

@Suite("Trading phase")
struct TradingPhaseTests {
    private func cards(_ count: Int, good: GoodType = .sugar) -> [GoodsCard] {
        Array(repeating: GoodsCard(good: good), count: count)
    }

    private func state(
        handCount: Int = 0, deckCount: Int = 8, offices: Int = 0, customs: Bool = false
    ) throws -> TradingState {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        try flow.pass(by: 0)
        var hand = Hand()
        try hand.add(cards(handCount), limit: 8)
        var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
        var tableau = Tableau()
        for _ in 0..<offices {
            try stock.purchase(.office, for: &tableau)
        }
        if customs {
            try stock.purchase(.customsHouse, for: &tableau)
        }
        return TradingState(
            turnFlow: flow, hands: [hand, Hand()], tableaux: [tableau, Tableau()],
            deck: DrawDeck(cards: cards(deckCount, good: .tea)),
            marketplace: try Marketplace(visibleCards: cards(6, good: .indigo))
        )
    }

    @Test(arguments: [
        (4, false, true), (5, false, false), (6, false, false),
        (6, true, true), (7, true, false)
    ])
    func EC1EC2EC25DrawHonorsHandCapacity(handCount: Int, customs: Bool, allowed: Bool) throws {
        let initial = try state(handCount: handCount, customs: customs)
        if allowed {
            let result = try TradingPhaseRules.apply(.draw, by: 0, to: initial)
            #expect(result.state.hands[0].count == handCount + 2)
            #expect(result.state.deck.remaining == 6)
            #expect(result.outcome == .drew(base: 2, officeExtras: 0, deckEmptied: false))
            #expect(result.state.turnFlow.currentSeat == 1)
        } else {
            #expect(throws: TurnFlowError.cannotDrawMustDeliver) {
                try TradingPhaseRules.apply(.draw, by: 0, to: initial)
            }
            #expect(initial.hands[0].count == handCount)
            #expect(initial.deck.remaining == 8)
            #expect(initial.turnFlow.currentSeat == 0)
        }
    }

    @Test func EC4EC5DrawOneRemainingCardSignalsDeckEmpty() throws {
        let initial = try state(handCount: 5, deckCount: 1, offices: 1)
        let result = try TradingPhaseRules.apply(.draw, by: 0, to: initial)
        #expect(result.state.hands[0].count == 6)
        #expect(result.outcome == .drew(base: 1, officeExtras: 0, deckEmptied: true))
    }

    @Test func EC25OneRemainingCardCanBeDrawnAtSevenWithCustomsHouse() throws {
        let initial = try state(handCount: 7, deckCount: 1, customs: true)
        let result = try TradingPhaseRules.apply(.draw, by: 0, to: initial)
        #expect(result.state.hands[0].count == 8)
        #expect(result.outcome == .drew(base: 1, officeExtras: 0, deckEmptied: true))
    }

    @Test func EC4BaseDrawCanEmptyDeck() throws {
        let result = try TradingPhaseRules.apply(.draw, by: 0, to: state(deckCount: 2, offices: 1))
        #expect(result.outcome == .drew(base: 2, officeExtras: 0, deckEmptied: true))
    }

    @Test func EC3EC27OfficeExtrasAreCappedByHandRoom() throws {
        for (handCount, expectedExtras) in [(3, 1), (4, 0)] {
            let initial = try state(handCount: handCount, offices: 2)
            let result = try TradingPhaseRules.apply(.draw, by: 0, to: initial)
            #expect(result.outcome == .drew(base: 2, officeExtras: expectedExtras, deckEmptied: false))
            #expect(result.state.hands[0].count == 6)
            #expect(result.state.deck.remaining == 8 - 2 - expectedExtras)
        }
        let full = try state(handCount: 6, offices: 2)
        #expect(throws: TurnFlowError.cannotDrawMustDeliver) {
            try TradingPhaseRules.apply(.draw, by: 0, to: full)
        }
    }

    @Test func EC6EC27OfficeExtrasAreCappedByDeckAndSignalEmpty() throws {
        let initial = try state(deckCount: 3, offices: 2)
        let result = try TradingPhaseRules.apply(.draw, by: 0, to: initial)
        #expect(result.outcome == .drew(base: 2, officeExtras: 1, deckEmptied: true))
        #expect(result.state.hands[0].count == 3)
        #expect(result.state.deck.isEmpty)
    }

    @Test(arguments: [1, 6])
    func deliverRemovesCardsAndChangesMarketplaceWithoutDrawing(count: Int) throws {
        let initial = try state(handCount: count, offices: 1)
        let placements = (0..<count).map { DeliveryPlacement(slot: $0, card: GoodsCard(good: .sugar)) }
        let result = try TradingPhaseRules.apply(.deliver(placements), by: 0, to: initial)
        #expect(result.outcome == .delivered(.sugar))
        #expect(result.state.hands[0].count == 0)
        #expect(result.state.marketplace.demand(for: .sugar) == count)
        #expect(result.state.deck == initial.deck)
        #expect(result.state.turnFlow.currentSeat == 1)
    }

    @Test func invalidDeliveryAndMissingCardsFailAtomically() throws {
        let initial = try state(handCount: 1)
        let duplicate = [
            DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar)),
            DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar))
        ]
        #expect(throws: MarketplaceError.duplicateSlot) {
            try TradingPhaseRules.apply(.deliver(duplicate), by: 0, to: initial)
        }
        let missing = [DeliveryPlacement(slot: 0, card: GoodsCard(good: .tea))]
        #expect(throws: HandError.insufficientCards(good: .tea, required: 1, available: 0)) {
            try TradingPhaseRules.apply(.deliver(missing), by: 0, to: initial)
        }
        #expect(initial.marketplace.demand(for: .indigo) == 6)
        #expect(initial.hands[0].count == 1)
        #expect(initial.turnFlow.currentSeat == 0)
        #expect(initial.deck.remaining == 8)
    }

    @Test func EC24SkipOnlyAllowedWithEmptyDeckAndDrawThenRejected() throws {
        let normal = try state()
        #expect(throws: TurnFlowError.skipOnlyWhenDeckEmpty) {
            try TradingPhaseRules.apply(.skip, by: 0, to: normal)
        }
        let empty = try state(deckCount: 0)
        #expect(throws: TurnFlowError.cannotDrawMustDeliver) {
            try TradingPhaseRules.apply(.draw, by: 0, to: empty)
        }
        let result = try TradingPhaseRules.apply(.skip, by: 0, to: empty)
        #expect(result.outcome == .skipped)
        #expect(result.state.turnFlow.currentSeat == 1)
    }

    @Test func deliveryIsAllowedWhenDeckIsEmpty() throws {
        let initial = try state(handCount: 1, deckCount: 0)
        let placement = DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar))
        let result = try TradingPhaseRules.apply(.deliver([placement]), by: 0, to: initial)
        #expect(result.outcome == .delivered(.sugar))
        #expect(result.state.deck.isEmpty)
    }

    @Test func wrongPlayerAndWrongPhaseAreRejected() throws {
        let initial = try state()
        #expect(throws: TurnFlowError.notYourTurn) {
            try TradingPhaseRules.apply(.draw, by: 1, to: initial)
        }
        var planning = initial
        planning.turnFlow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try planning.turnFlow.start()
        #expect(throws: TurnFlowError.wrongPhase) {
            try TradingPhaseRules.apply(.draw, by: 0, to: planning)
        }
    }

    @Test func inconsistentPlayerStateIsRejected() throws {
        var initial = try state()
        initial.hands.removeLast()
        #expect(throws: TradingPhaseError.invalidPlayerState) {
            try TradingPhaseRules.apply(.draw, by: 0, to: initial)
        }
    }
}
