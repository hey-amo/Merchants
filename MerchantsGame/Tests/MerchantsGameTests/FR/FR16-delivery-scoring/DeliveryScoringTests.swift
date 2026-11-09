import Testing
@testable import MerchantsGame

@Suite("Delivery scoring")
struct DeliveryScoringTests {
    private let players = [PlayerID("one"), PlayerID("two")]

    private func market(_ demand: Int) throws -> Marketplace {
        let cards = (0..<6).map { GoodsCard(good: $0 < demand ? .sugar : .tea) }
        return try Marketplace(visibleCards: cards)
    }

    private func fleet(_ count: Int) throws -> Fleet {
        var fleet = Fleet()
        if count > 2 { fleet.addShip(kind: .large) }
        for index in 0..<count {
            try fleet.load(GoodsCube(good: .sugar), onto: min(index, 2))
        }
        return fleet
    }

    private func tableau(agreements: Int) throws -> Tableau {
        var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
        var tableau = Tableau()
        for _ in 0..<agreements {
            try stock.purchase(.tradeAgreement, for: &tableau)
        }
        return tableau
    }

    @Test func EC13EC14ThresholdAndMultipleAgreements() throws {
        for demand in [2, 3] {
            let result = try DeliveryScoring.transactions(
                for: .sugar, marketplace: market(demand), players: players,
                fleets: [fleet(1), fleet(0)], tableaux: [tableau(agreements: 2), Tableau()], rules: .standard
            )
            #expect(result.first?.amount == demand)
            #expect(result.count == (demand == 3 ? 2 : 1))
            if demand == 3 {
                #expect(result[1] == Transaction(player: players[0], amount: 4, direction: .credit, reason: .tradeAgreementBonus))
            }
        }
    }

    @Test func EC15EC28EC30LargeShipAndBothPlayersScoreAfterMarketplacePlacement() throws {
        var marketplace = try market(1)
        try marketplace.deliver([DeliveryPlacement(slot: 0, card: GoodsCard(good: .sugar)),
                                 DeliveryPlacement(slot: 1, card: GoodsCard(good: .sugar))])
        let result = try DeliveryScoring.transactions(
            for: .sugar, marketplace: marketplace, players: players,
            fleets: [fleet(4), fleet(1)], tableaux: [Tableau(), tableau(agreements: 1)], rules: .standard
        )
        #expect(marketplace.demand(for: .sugar) == 2)
        #expect(result == [
            Transaction(player: players[0], amount: 8, direction: .credit, reason: .deliveryPayout(.sugar)),
            Transaction(player: players[1], amount: 2, direction: .credit, reason: .deliveryPayout(.sugar))
        ])
    }

    @Test func EC16ZeroPayoutAndInvalidPlayerLists() throws {
        let marketplace = try market(0)
        #expect(try DeliveryScoring.transactions(
            for: .sugar, marketplace: marketplace, players: players,
            fleets: [fleet(2), fleet(0)], tableaux: [Tableau(), Tableau()], rules: .standard
        ).isEmpty)
        #expect(throws: DeliveryScoringError.invalidPlayers) {
            try DeliveryScoring.transactions(for: .sugar, marketplace: marketplace, players: [players[0], players[0]],
                                             fleets: [fleet(1), fleet(1)], tableaux: [Tableau(), Tableau()], rules: .standard)
        }
    }

    @Test func EC13AgreementsApplyToEveryPlayersDeliveryAndOnlyOnce() throws {
        let result = try DeliveryScoring.transactions(
            for: .sugar, marketplace: market(3), players: players,
            fleets: [fleet(2), fleet(1)], tableaux: [tableau(agreements: 1), tableau(agreements: 1)], rules: .standard
        )
        #expect(result == [
            Transaction(player: players[0], amount: 6, direction: .credit, reason: .deliveryPayout(.sugar)),
            Transaction(player: players[0], amount: 2, direction: .credit, reason: .tradeAgreementBonus),
            Transaction(player: players[1], amount: 3, direction: .credit, reason: .deliveryPayout(.sugar)),
            Transaction(player: players[1], amount: 2, direction: .credit, reason: .tradeAgreementBonus)
        ])
    }
}
