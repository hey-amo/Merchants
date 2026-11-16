// Tests FR25 defaults, validation, serialization compatibility, and rule overrides.
// Owns coverage for stored tunables and their effects on gameplay.
// Does not test game-state restoration or store behavior.

import Foundation
import XCTest
@testable import MerchantsGame

final class GameRulesTests: XCTestCase {
    func testStandardRulesMatchPRDSpecialCardValues() throws {
        let rules = GameRules.standard
        let catalog = rules.specialCardCatalog
        let expected: [(SpecialCardKind, Int, [Int], Int?)] = [
            (.ship, 10, [10, 8, 6], nil),
            (.largeShip, 18, [2, 3, 4], 1),
            (.office, 8, [2, 2, 2], nil),
            (.crane, 12, [2, 2, 2], nil),
            (.tradeAgreement, 11, [2, 2, 2], nil),
            (.customsHouse, 8, [2, 3, 4], 1)
        ]

        XCTAssertEqual(rules.handLimitBase, 6)
        XCTAssertEqual(rules.tradeAgreementBonusPerCard, 2)
        XCTAssertEqual(rules.tradeAgreementMinimumPayout, 2)
        XCTAssertEqual(rules.endGameRule, .oneMoreTurn)
        for (kind, price, stockByPlayerCount, ownershipLimit) in expected {
            let entry = catalog.entry(for: kind)
            XCTAssertEqual(entry.price, price)
            XCTAssertEqual(entry.stockByPlayerCount, stockByPlayerCount)
            XCTAssertEqual(entry.ownershipLimit, ownershipLimit)
        }
    }

    func testCustomTunablesRoundTripThroughCodable() throws {
        var entries: [SpecialCardKind: SpecialCardCatalog.Entry] = [:]
        for kind in SpecialCardKind.allCases {
            entries[kind] = SpecialCardCatalog.standard.entry(for: kind)
        }
        entries[.largeShip] = try .init(
            price: 20,
            stockByPlayerCount: [2, 3, 4],
            ownershipLimit: 1
        )
        let catalog = try SpecialCardCatalog(entries: entries)
        let rules = try GameRules(
            specialCardCatalog: catalog,
            handLimitBase: 9,
            tradeAgreementBonusPerCard: 5,
            tradeAgreementMinimumPayout: 10,
            endGameRule: .immediate
        )

        let data = try JSONEncoder().encode(rules)
        XCTAssertEqual(try JSONDecoder().decode(GameRules.self, from: data), rules)
    }

    func testLegacyRulesWithoutHandLimitDecodeWithStandardValue() throws {
        let encoded = try JSONEncoder().encode(GameRules.standard)
        var object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "handLimitBase")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(GameRules.self, from: legacyData)
        XCTAssertEqual(decoded, .standard)
    }

    func testHandLimitMustFitInitialDealAndCustomsHouseBonus() throws {
        for invalidLimit in [Int.min, -1, 0, 1, 2, Int.max - 1, Int.max] {
            XCTAssertThrowsError(
                try GameRules(specialCardCatalog: .standard, handLimitBase: invalidLimit),
                "Expected hand limit \(invalidLimit) to be rejected"
            ) {
                XCTAssertEqual($0 as? SpecialCardError, .invalidRules)
            }
        }

        XCTAssertNoThrow(try GameRules(specialCardCatalog: .standard, handLimitBase: 3))
        XCTAssertNoThrow(
            try GameRules(specialCardCatalog: .standard, handLimitBase: Int.max - 2)
        )
    }

    func testDecodingRejectsImpossibleOrOverflowingHandLimits() throws {
        let encoded = try JSONEncoder().encode(GameRules.standard)
        let decoder = JSONDecoder()
        for invalidLimit in [Int.min, 0, 1, 2, Int.max - 1, Int.max] {
            var object = try XCTUnwrap(
                try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            )
            object["handLimitBase"] = NSNumber(value: invalidLimit)
            let invalidData = try JSONSerialization.data(withJSONObject: object)

            XCTAssertThrowsError(
                try decoder.decode(GameRules.self, from: invalidData),
                "Expected decoded hand limit \(invalidLimit) to be rejected"
            ) {
                XCTAssertEqual($0 as? SpecialCardError, .invalidRules)
            }
        }
    }

    func testCustomHandLimitControlsTradingDrawLegality() throws {
        let rules = try GameRules(specialCardCatalog: .standard, handLimitBase: 4)
        let succeeds = try TradingPhaseRules.apply(
            .draw,
            by: 0,
            to: tradingState(handCount: 2, rules: rules)
        )
        XCTAssertEqual(succeeds.state.hands[0].count, 4)

        XCTAssertThrowsError(
            try TradingPhaseRules.apply(
                .draw,
                by: 0,
                to: tradingState(handCount: 3, rules: rules)
            )
        ) {
            XCTAssertEqual($0 as? TurnFlowError, .cannotDrawMustDeliver)
        }
    }

    func testCustomCatalogPriceIsUsedForPurchaseAndFailureIsAtomic() throws {
        var entries: [SpecialCardKind: SpecialCardCatalog.Entry] = [:]
        for kind in SpecialCardKind.allCases {
            entries[kind] = SpecialCardCatalog.standard.entry(for: kind)
        }
        entries[.largeShip] = try .init(
            price: 20,
            stockByPlayerCount: [2, 3, 4],
            ownershipLimit: 1
        )
        let catalog = try SpecialCardCatalog(entries: entries)
        let rules = try GameRules(specialCardCatalog: catalog)
        let players = [PlayerID("first"), PlayerID("second")]
        let affordable = try planningState(players: players, rules: rules, balance: 20)
        let purchased = try PlanningPhaseRules.apply(
            .buy(.largeShip, loadCubes: [.sugar, .tea]),
            by: players[0],
            to: affordable
        )

        XCTAssertEqual(try purchased.bank.balance(of: players[0]).available, 0)
        XCTAssertEqual(purchased.fleets[0].ships.last?.kind, .large)
        XCTAssertEqual(purchased.fleets[0].ships.last?.cubes.map(\.good), [.sugar, .tea])

        let short = try planningState(players: players, rules: rules, balance: 19)
        XCTAssertThrowsError(
            try PlanningPhaseRules.apply(
                .buy(.largeShip, loadCubes: [.sugar, .tea]),
                by: players[0],
                to: short
            )
        ) {
            XCTAssertEqual(
                $0 as? PlanningError,
                .banking(.coin(player: .insufficientFunds(required: 20, available: 19)))
            )
        }
        XCTAssertEqual(try short.bank.balance(of: players[0]).available, 19)
        XCTAssertEqual(short.fleets[0].ships.count, 2)
    }

    private func tradingState(handCount: Int, rules: GameRules) throws -> TradingState {
        var turnFlow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try turnFlow.start()
        try turnFlow.pass(by: 0)

        var hand = Hand()
        try hand.add(
            Array(repeating: GoodsCard(good: .sugar), count: handCount),
            limit: 10
        )
        let deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .tea), count: 4))
        let marketplace = try Marketplace(
            visibleCards: Array(repeating: GoodsCard(good: .indigo), count: Marketplace.slotCount)
        )
        return TradingState(
            turnFlow: turnFlow,
            hands: [hand, Hand()],
            tableaux: [Tableau(), Tableau()],
            deck: deck,
            marketplace: marketplace,
            rules: rules
        )
    }

    private func planningState(
        players: [PlayerID],
        rules: GameRules,
        balance: Int
    ) throws -> PlanningState {
        let bank = try Bank(restoring: [players[0]: balance, players[1]: 0])
        var turn = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try turn.start()
        return try PlanningState(
            players: players,
            rules: rules,
            turn: turn,
            bank: bank,
            supply: CubeSupply(),
            fleets: [Fleet(), Fleet()],
            stock: SpecialCardStock(playerCount: 2, catalog: rules.specialCardCatalog),
            tableaus: [Tableau(), Tableau()]
        )
    }
}
