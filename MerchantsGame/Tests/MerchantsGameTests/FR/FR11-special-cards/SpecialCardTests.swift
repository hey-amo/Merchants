import Foundation
import XCTest
@testable import MerchantsGame

final class SpecialCardTests: XCTestCase {
    func testStandardCatalogPricesStockAndLimits() throws {
        let catalog = SpecialCardCatalog.standard
        let expected: [(SpecialCardKind, Int, [Int], Int?)] = [
            (.ship, 10, [10, 8, 6], nil),
            (.largeShip, 18, [2, 3, 4], 1),
            (.office, 8, [2, 2, 2], nil),
            (.crane, 12, [2, 2, 2], nil),
            (.tradeAgreement, 11, [2, 2, 2], nil),
            (.customsHouse, 8, [2, 3, 4], 1)
        ]
        for (kind, price, counts, limit) in expected {
            XCTAssertEqual(catalog.entry(for: kind).price, price)
            XCTAssertEqual(catalog.entry(for: kind).ownershipLimit, limit)
            for players in 2...4 {
                XCTAssertEqual(try catalog.stock(for: kind, playerCount: players), counts[players - 2])
            }
        }
        XCTAssertThrowsError(try catalog.stock(for: .ship, playerCount: 1)) {
            XCTAssertEqual($0 as? SpecialCardError, .invalidPlayerCount)
        }
    }

    func testExhaustionForEveryKindIsAtomic() throws {
        for kind in SpecialCardKind.allCases {
            var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
            var tableaus = [Tableau(), Tableau()]
            let count = stock.available(of: kind)
            for index in 0..<count {
                try stock.purchase(kind, for: &tableaus[index % tableaus.count])
            }
            let savedStock = stock
            let savedTableau = tableaus[0]
            XCTAssertThrowsError(try stock.purchase(kind, for: &tableaus[0])) {
                XCTAssertEqual($0 as? SpecialCardError, .outOfStock(kind))
            }
            XCTAssertEqual(stock, savedStock)
            XCTAssertEqual(tableaus[0], savedTableau)
        }
    }

    func testOwnershipLimitsAndIndependentPlayers() throws {
        for kind in [SpecialCardKind.largeShip, .customsHouse] {
            var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
            var first = Tableau()
            var second = Tableau()
            try stock.purchase(kind, for: &first)
            let savedStock = stock
            let savedFirst = first
            XCTAssertThrowsError(try stock.purchase(kind, for: &first)) {
                XCTAssertEqual($0 as? SpecialCardError, .ownershipLimitReached(kind))
            }
            XCTAssertEqual(stock, savedStock)
            XCTAssertEqual(first, savedFirst)
            try stock.purchase(kind, for: &second)
            XCTAssertEqual(second.count(of: kind), 1)
        }
    }

    func testEffectsStackAndUseStrictPayoutThreshold() throws {
        var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
        var tableau = Tableau()
        for kind in [SpecialCardKind.office, .office, .crane, .crane, .tradeAgreement, .tradeAgreement, .customsHouse] {
            try stock.purchase(kind, for: &tableau)
        }
        let effects = SpecialCardEffects(tableau: tableau, rules: .standard)
        XCTAssertEqual(effects.extraExchangesOnExchange, 2)
        XCTAssertEqual(effects.freeExchangeOnCraneBuy, 1)
        XCTAssertEqual(effects.officeExtraDraws, 2)
        XCTAssertEqual(effects.handLimitBonus, 2)
        XCTAssertEqual(try effects.tradeAgreementBonus(for: 0), 0)
        XCTAssertEqual(try effects.tradeAgreementBonus(for: 2), 0)
        XCTAssertEqual(try effects.tradeAgreementBonus(for: 3), 4)
        XCTAssertThrowsError(try effects.tradeAgreementBonus(for: -1))
    }

    func testCustomRulesAndCatalogAreUsed() throws {
        var entries: [SpecialCardKind: SpecialCardCatalog.Entry] = [:]
        for kind in SpecialCardKind.allCases {
            entries[kind] = SpecialCardCatalog.standard.entry(for: kind)
        }
        entries[.office] = try .init(price: 4, stockByPlayerCount: [3, 4, 5], ownershipLimit: 2)
        let catalog = try SpecialCardCatalog(entries: entries)
        let rules = try GameRules(specialCardCatalog: catalog, tradeAgreementBonusPerCard: 5, tradeAgreementMinimumPayout: 10)
        var stock = try SpecialCardStock(playerCount: 2, catalog: rules.specialCardCatalog)
        var tableau = Tableau()
        try stock.purchase(.tradeAgreement, for: &tableau)
        XCTAssertEqual(stock.available(of: .office), 3)
        XCTAssertEqual(stock.catalog.entry(for: .office).price, 4)
        let effects = SpecialCardEffects(tableau: tableau, rules: rules)
        XCTAssertEqual(try effects.tradeAgreementBonus(for: 10), 0)
        XCTAssertEqual(try effects.tradeAgreementBonus(for: 11), 5)
        let data = try JSONEncoder().encode(rules)
        XCTAssertEqual(try JSONDecoder().decode(GameRules.self, from: data), rules)
    }

    func testRoundTripAndLegacyRules() throws {
        var stock = try SpecialCardStock(playerCount: 3, catalog: .standard)
        var tableau = Tableau()
        try stock.purchase(.office, for: &tableau)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(SpecialCardStock.self, from: encoder.encode(stock)), stock)
        XCTAssertEqual(try decoder.decode(Tableau.self, from: encoder.encode(tableau)), tableau)
        XCTAssertEqual(try decoder.decode(GameRules.self, from: Data("{}".utf8)), .standard)
        XCTAssertThrowsError(try decoder.decode(GameRules.self, from: Data(#"{"tradeAgreementBonusPerCard":null}"#.utf8)))
    }

    func testInvalidCatalogAndRestorationAreRejected() throws {
        XCTAssertThrowsError(try SpecialCardCatalog.Entry(price: -1, stockByPlayerCount: [1, 1, 1], ownershipLimit: nil))
        XCTAssertThrowsError(try SpecialCardCatalog.Entry(price: 1, stockByPlayerCount: [1, 1], ownershipLimit: nil))
        XCTAssertThrowsError(try SpecialCardCatalog.Entry(price: 1, stockByPlayerCount: [1, 1, 1], ownershipLimit: 0))
        XCTAssertThrowsError(try SpecialCardCatalog(entries: [:]))
        XCTAssertThrowsError(try SpecialCardStock(playerCount: 5, catalog: .standard))
        XCTAssertThrowsError(try GameRules(specialCardCatalog: .standard, tradeAgreementBonusPerCard: -1))

        let decoder = JSONDecoder()
        let invalidTableau = Data(#"{"counts":[{"office":{}},-1]}"#.utf8)
        XCTAssertThrowsError(try decoder.decode(Tableau.self, from: invalidTableau)) {
            XCTAssertEqual($0 as? SpecialCardError, .invalidTableau)
        }
        let invalidEntry = Data(#"{"price":1,"stockByPlayerCount":[1,-1,1]}"#.utf8)
        XCTAssertThrowsError(try decoder.decode(SpecialCardCatalog.Entry.self, from: invalidEntry))
    }

    func testInvalidStockRestorationIsRejected() throws {
        struct StockFixture: Encodable {
            let catalog: SpecialCardCatalog = .standard
            let playerCount: Int = 2
            let remaining: [SpecialCardKind: Int]
        }

        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        var counts: [SpecialCardKind: Int] = [:]
        for kind in SpecialCardKind.allCases {
            counts[kind] = try SpecialCardCatalog.standard.stock(for: kind, playerCount: 2)
        }
        for invalidCount in [-1, 11] {
            counts[.ship] = invalidCount
            let data = try encoder.encode(StockFixture(remaining: counts))
            XCTAssertThrowsError(try decoder.decode(SpecialCardStock.self, from: data)) {
                XCTAssertEqual($0 as? SpecialCardError, .invalidStock)
            }
        }
        counts.removeValue(forKey: .ship)
        let missing = try encoder.encode(StockFixture(remaining: counts))
        XCTAssertThrowsError(try decoder.decode(SpecialCardStock.self, from: missing)) {
            XCTAssertEqual($0 as? SpecialCardError, .invalidStock)
        }
    }

    func testOverflowIsRejectedWithoutChangingStock() throws {
        struct TableauFixture: Encodable {
            let counts: [SpecialCardKind: Int]
        }
        let data = try JSONEncoder().encode(TableauFixture(counts: [.ship: Int.max, .tradeAgreement: Int.max]))
        var tableau = try JSONDecoder().decode(Tableau.self, from: data)
        var stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
        let savedTableau = tableau
        let savedStock = stock
        XCTAssertThrowsError(try stock.purchase(.ship, for: &tableau)) {
            XCTAssertEqual($0 as? SpecialCardError, .overflow)
        }
        XCTAssertEqual(stock, savedStock)
        XCTAssertEqual(tableau, savedTableau)
        let effects = SpecialCardEffects(tableau: tableau, rules: .standard)
        XCTAssertThrowsError(try effects.tradeAgreementBonus(for: 3)) {
            XCTAssertEqual($0 as? SpecialCardError, .overflow)
        }
    }
}
