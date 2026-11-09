import Foundation
import XCTest
@testable import MerchantsGame

final class DrawDeckTests: XCTestCase {
    func testStandardDeckHasTenCardsOfEachGood() throws {
        var random = SeededRandomSource(seed: 123)
        var deck = DeckBuilder.standardDeck(using: &random)

        XCTAssertEqual(deck.remaining, 60)
        XCTAssertFalse(deck.isEmpty)
        let cards = try deck.draw(60)
        XCTAssertEqual(cards.count, 60)
        for good in GoodType.allCases {
            XCTAssertEqual(cards.filter { $0.good == good }.count, 10)
        }
        XCTAssertEqual(deck.remaining, 0)
        XCTAssertTrue(deck.isEmpty)
    }

    func testSeededStandardDecksAreReproducible() throws {
        var firstRandom = SeededRandomSource(seed: 42)
        var secondRandom = SeededRandomSource(seed: 42)
        var differentRandom = SeededRandomSource(seed: 43)
        var first = DeckBuilder.standardDeck(using: &firstRandom)
        var second = DeckBuilder.standardDeck(using: &secondRandom)
        var different = DeckBuilder.standardDeck(using: &differentRandom)

        let firstCards = try first.draw(60)
        XCTAssertEqual(firstCards, try second.draw(60))
        XCTAssertNotEqual(firstCards, try different.draw(60))
        XCTAssertEqual(firstRandom, secondRandom)
    }

    func testDrawZeroLeavesNonemptyDeckUnchanged() throws {
        var deck = DrawDeck(cards: [.init(good: .sugar)])
        let original = deck

        XCTAssertEqual(try deck.draw(0), [])
        XCTAssertEqual(deck, original)
    }

    func testDrawReturnsCardsFromTopInOrder() throws {
        let cards: [GoodsCard] = [.init(good: .sugar), .init(good: .tea), .init(good: .silk)]
        var deck = DrawDeck(cards: cards)

        XCTAssertEqual(try deck.draw(2), Array(cards.prefix(2)))
        XCTAssertEqual(deck.remaining, 1)
        XCTAssertEqual(try deck.draw(1), [cards[2]])
        XCTAssertTrue(deck.isEmpty)
    }

    func testDrawingMoreThanRemainingReturnsRemainder() throws {
        let cards: [GoodsCard] = [.init(good: .sugar), .init(good: .tea)]
        var deck = DrawDeck(cards: cards)

        XCTAssertEqual(try deck.draw(Int.max), cards)
        XCTAssertTrue(deck.isEmpty)
        XCTAssertThrowsError(try deck.draw(1)) {
            XCTAssertEqual($0 as? DrawDeckError, .empty)
        }
    }

    func testEmptyDeckRejectsDrawIncludingZero() {
        var deck = DrawDeck(cards: [])
        for count in [0, 1] {
            XCTAssertThrowsError(try deck.draw(count)) {
                XCTAssertEqual($0 as? DrawDeckError, .empty)
            }
        }
        XCTAssertTrue(deck.isEmpty)
    }

    func testNegativeCountIsRejectedWithoutChangingDeck() {
        var deck = DrawDeck(cards: [.init(good: .sugar)])
        let original = deck
        XCTAssertThrowsError(try deck.draw(-1)) {
            XCTAssertEqual($0 as? DrawDeckError, .invalidCount)
        }
        XCTAssertEqual(deck, original)

        var empty = DrawDeck(cards: [])
        XCTAssertThrowsError(try empty.draw(-1)) {
            XCTAssertEqual($0 as? DrawDeckError, .invalidCount)
        }
        XCTAssertTrue(empty.isEmpty)
    }

    func testCodableRoundTripPreservesRemainingDrawOrder() throws {
        let cards: [GoodsCard] = [.init(good: .sugar), .init(good: .tea), .init(good: .silk)]
        var deck = DrawDeck(cards: cards)
        _ = try deck.draw(1)
        let data = try JSONEncoder().encode(deck)
        var restored = try JSONDecoder().decode(DrawDeck.self, from: data)

        XCTAssertEqual(restored, deck)
        XCTAssertEqual(try restored.draw(2), Array(cards.suffix(2)))
    }
}
