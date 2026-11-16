import Foundation
import XCTest
@testable import MerchantsGame

final class HandTests: XCTestCase {
    private func cards(_ good: GoodType, _ count: Int) -> [GoodsCard] {
        Array(repeating: GoodsCard(good: good), count: count)
    }

    func testBaseLimitComesFromStandardRules() {
        XCTAssertEqual(GameRules.standard.handLimitBase, 6)
        XCTAssertEqual(HandLimit.base, GameRules.standard.handLimitBase)
    }

    func testRoomAtZeroOneAndSixCards() throws {
        var hand = Hand()
        XCTAssertEqual(try hand.room(limit: 6), 6)
        try hand.add(cards(.sugar, 1), limit: 6)
        XCTAssertEqual(try hand.room(limit: 6), 5)
        try hand.add(cards(.tea, 5), limit: 6)
        XCTAssertEqual(try hand.room(limit: 6), 0)
        XCTAssertEqual(try hand.room(limit: 8), 2)
        XCTAssertEqual(try hand.room(limit: 4), 0)
    }

    func testAddsUpToLimitAndRejectsMoreAtomically() throws {
        var hand = Hand()
        try hand.add(cards(.sugar, 6), limit: 6)
        let original = hand
        XCTAssertThrowsError(try hand.add(cards(.tea, 1), limit: 6)) {
            XCTAssertEqual($0 as? HandError, .limitExceeded(limit: 6, attempted: 7))
        }
        XCTAssertEqual(hand, original)
        try hand.add(cards(.tea, 2), limit: 8)
        XCTAssertEqual(hand.count, 8)
        XCTAssertEqual(hand.count(of: .sugar), 6)
        XCTAssertEqual(hand.count(of: .tea), 2)
        XCTAssertThrowsError(try hand.add(cards(.tea, 1), limit: 8)) {
            XCTAssertEqual($0 as? HandError, .limitExceeded(limit: 8, attempted: 9))
        }
        XCTAssertEqual(hand.count, 8)
    }

    func testRemoveAllOfGoodAndRejectTooManyAtomically() throws {
        var hand = Hand()
        try hand.add(cards(.sugar, 2) + cards(.tea, 1), limit: 6)
        let original = hand
        XCTAssertThrowsError(try hand.remove(good: .sugar, count: 3)) {
            XCTAssertEqual($0 as? HandError, .insufficientCards(good: .sugar, required: 3, available: 2))
        }
        XCTAssertEqual(hand, original)
        XCTAssertEqual(try hand.remove(good: .sugar, count: 2), cards(.sugar, 2))
        XCTAssertEqual(hand.count(of: .sugar), 0)
        XCTAssertEqual(hand.count(of: .tea), 1)
        XCTAssertEqual(try hand.remove(good: .sugar, count: 0), [])
    }

    func testRejectsInvalidLimitsAndCountsWithoutMutation() throws {
        var hand = Hand()
        try hand.add(cards(.sugar, 1), limit: 6)
        let original = hand
        XCTAssertThrowsError(try hand.room(limit: -1)) {
            XCTAssertEqual($0 as? HandError, .invalidLimit(-1))
        }
        XCTAssertThrowsError(try hand.add(cards(.tea, 1), limit: -1)) {
            XCTAssertEqual($0 as? HandError, .invalidLimit(-1))
        }
        XCTAssertThrowsError(try hand.remove(good: .sugar, count: -1)) {
            XCTAssertEqual($0 as? HandError, .invalidCount(-1))
        }
        XCTAssertEqual(hand, original)
    }

    func testRestorationPreservesCards() throws {
        var hand = Hand()
        try hand.add(cards(.tea, 2) + cards(.silk, 1), limit: 6)
        let data = try JSONEncoder().encode(hand)
        var restored = try JSONDecoder().decode(Hand.self, from: data)
        XCTAssertEqual(restored, hand)
        XCTAssertEqual(try restored.remove(good: .tea, count: 2), cards(.tea, 2))
        XCTAssertEqual(restored.count(of: .silk), 1)
    }
}
