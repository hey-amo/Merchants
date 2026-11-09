import Foundation
import XCTest
@testable import MerchantsGame

final class MarketplaceTests: XCTestCase {
    private func card(_ good: GoodType) -> GoodsCard {
        GoodsCard(good: good)
    }

    private func market() throws -> Marketplace {
        try Marketplace(visibleCards: GoodType.allCases.map { card($0) })
    }

    func testRequiresExactlySixInitialSlots() {
        for count in [0, 5, 7] {
            XCTAssertThrowsError(try Marketplace(visibleCards: Array(repeating: card(.tea), count: count))) {
                XCTAssertEqual($0 as? MarketplaceError, .invalidSlotCount)
            }
        }
    }

    func testEC15EC28DemandAndSameColourCover() throws {
        var marketplace = try market()
        try marketplace.deliver([
            DeliveryPlacement(slot: 0, card: card(.sugar)),
            DeliveryPlacement(slot: 1, card: card(.sugar))
        ])
        XCTAssertEqual(marketplace.demand(for: .sugar), 2)
        XCTAssertEqual(marketplace.demand(for: .indigo), 0)
        XCTAssertEqual(marketplace.visibleCards.count, 6)
        XCTAssertEqual(marketplace.totalCardCount, 8)
    }

    func testDeliverAllSixSlots() throws {
        var marketplace = try market()
        try marketplace.deliver((0..<6).map { DeliveryPlacement(slot: $0, card: card(.silk)) })
        XCTAssertEqual(marketplace.demand(for: .silk), 6)
        XCTAssertEqual(marketplace.visibleCards, Array(repeating: card(.silk), count: 6))
        XCTAssertEqual(marketplace.totalCardCount, 12)
    }

    func testRejectsInvalidDeliveriesAtomically() throws {
        var marketplace = try market()
        let original = marketplace
        let cases: [([DeliveryPlacement], MarketplaceError)] = [
            ([], .emptyDelivery),
            ((0..<7).map { DeliveryPlacement(slot: $0, card: card(.tea)) }, .tooManyCards),
            ([DeliveryPlacement(slot: 0, card: card(.tea)), DeliveryPlacement(slot: 1, card: card(.silk))], .mixedGoods),
            ([DeliveryPlacement(slot: 0, card: card(.tea)), DeliveryPlacement(slot: 0, card: card(.tea))], .duplicateSlot),
            ([DeliveryPlacement(slot: 0, card: card(.tea)), DeliveryPlacement(slot: -1, card: card(.tea))], .slotOutOfRange),
            ([DeliveryPlacement(slot: 0, card: card(.tea)), DeliveryPlacement(slot: 6, card: card(.tea))], .slotOutOfRange)
        ]
        for (placements, expected) in cases {
            XCTAssertThrowsError(try marketplace.deliver(placements)) {
                XCTAssertEqual($0 as? MarketplaceError, expected)
            }
            XCTAssertEqual(marketplace, original)
        }
    }

    func testCodableRoundTripAndInvalidSlotCount() throws {
        let marketplace = try market()
        let data = try JSONEncoder().encode(marketplace)
        XCTAssertEqual(try JSONDecoder().decode(Marketplace.self, from: data), marketplace)
        let invalid = Data(#"{"stacks":[]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Marketplace.self, from: invalid)) {
            XCTAssertEqual($0 as? MarketplaceError, .invalidSlotCount)
        }
        let emptyStack = Data(#"{"stacks":[[],[],[],[],[],[]]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Marketplace.self, from: emptyStack)) {
            XCTAssertEqual($0 as? MarketplaceError, .invalidSlotCount)
        }
    }
}
