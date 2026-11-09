import Foundation
import XCTest
@testable import MerchantsGame

final class GameEndingTests: XCTestCase {
    func testImmediateGameEndsAsSoonAsDeckEmpties() throws {
        var ending = GameEnding(rule: .immediate, order: try SeatOrder(count: 3, first: 1))
        try ending.deckEmptied()
        XCTAssertEqual(ending.status, .finished)
        XCTAssertThrowsError(try ending.deckEmptied()) {
            XCTAssertEqual($0 as? GameEndingError, .alreadyEnded)
        }
    }

    func testFinalRoundEndsAfterLastSeatForEachStartingSeat() throws {
        for first in 0..<3 {
            let order = try SeatOrder(count: 3, first: first)
            for emptyingSeat in 0..<3 {
                var ending = GameEnding(rule: .oneMoreTurn, order: order)
                try ending.deckEmptied()
                XCTAssertThrowsError(try ending.deckEmptied()) {
                    XCTAssertEqual($0 as? GameEndingError, .alreadyTriggered)
                }
                var seat = emptyingSeat
                while true {
                    try ending.turnCompleted(by: seat)
                    if seat == order.last {
                        XCTAssertEqual(ending.status, .finished)
                        break
                    }
                    XCTAssertEqual(ending.status, .finalRound)
                    seat = try order.next(after: seat)
                }
            }
        }
    }

    func testRulesDefaultAndRestoration() throws {
        XCTAssertEqual(GameRules.standard.endGameRule, .oneMoreTurn)
        XCTAssertEqual(try JSONDecoder().decode(GameRules.self, from: Data("{}".utf8)).endGameRule, .oneMoreTurn)
        var ending = GameEnding(rule: .oneMoreTurn, order: try SeatOrder(count: 2, first: 0))
        try ending.deckEmptied()
        let restored = try JSONDecoder().decode(GameEnding.self, from: JSONEncoder().encode(ending))
        XCTAssertEqual(restored, ending)
        XCTAssertThrowsError(try ending.turnCompleted(by: -1)) {
            XCTAssertEqual($0 as? GameEndingError, .invalidSeat)
        }
    }
}
