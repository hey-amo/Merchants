import Foundation
import XCTest
@testable import MerchantsGame

final class GoodsTests: XCTestCase {
    func testGoodTypesHaveExactlySixCasesInDeclarationOrder() {
        XCTAssertEqual(
            GoodType.allCases,
            [.sugar, .indigo, .spices, .tea, .silk, .lumber]
        )
    }

    func testComparisonMatchesDeclarationOrder() {
        let expected: [GoodType] = [.sugar, .indigo, .spices, .tea, .silk, .lumber]

        for (index, lhs) in expected.enumerated() {
            for (otherIndex, rhs) in expected.enumerated() {
                XCTAssertEqual(lhs < rhs, index < otherIndex)
            }
        }
        XCTAssertEqual(expected.reversed().sorted(), expected)
    }

    func testGoodsCardsAndCubesRetainTheirGoodAndHaveValueSemantics() {
        for good in GoodType.allCases {
            let card = GoodsCard(good: good)
            let cube = GoodsCube(good: good)
            XCTAssertEqual(card.good, good)
            XCTAssertEqual(cube.good, good)
            XCTAssertEqual(card, GoodsCard(good: good))
            XCTAssertEqual(cube, GoodsCube(good: good))
        }
        XCTAssertNotEqual(GoodsCard(good: .sugar), GoodsCard(good: .tea))
        XCTAssertNotEqual(GoodsCube(good: .sugar), GoodsCube(good: .tea))
        XCTAssertEqual(Set(GoodType.allCases.map { GoodsCard(good: $0) }).count, 6)
        XCTAssertEqual(Set(GoodType.allCases.map { GoodsCube(good: $0) }).count, 6)
    }

    func testGoodsVocabularyCodableRoundTripsForEveryGood() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for good in GoodType.allCases {
            let card = GoodsCard(good: good)
            let cube = GoodsCube(good: good)
            XCTAssertEqual(try decoder.decode(GoodType.self, from: encoder.encode(good)), good)
            XCTAssertEqual(try decoder.decode(GoodsCard.self, from: encoder.encode(card)), card)
            XCTAssertEqual(try decoder.decode(GoodsCube.self, from: encoder.encode(cube)), cube)
        }
    }
}
