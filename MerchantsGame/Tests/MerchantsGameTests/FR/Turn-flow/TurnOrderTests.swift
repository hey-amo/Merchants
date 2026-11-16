import Foundation
import XCTest
@testable import MerchantsGame

final class TurnOrderTests: XCTestCase {
    func testSnakeOrderForAllPlayerCountsAndRotatedFirstSeat() throws {
        for count in 2...4 {
            for first in 0..<count {
                let order = try SeatOrder(count: count, first: first)
                let expected = (0..<count).map { (first + count - 1 - $0 + count) % count }
                    + (0..<count).map { (first + $0) % count }
                XCTAssertEqual(try (0..<(count * 2)).map { try order.draftSeat(at: $0) }, expected)
                XCTAssertEqual(order.last, expected[0])
            }
        }
    }

    func testThreeSeatTurnsAndPlanningReset() throws {
        let order = try SeatOrder(count: 3, first: 1)
        var flow = TurnFlow(order: order)
        XCTAssertThrowsError(try flow.pass(by: 1)) { XCTAssertEqual($0 as? TurnFlowError, .gameNotStarted) }
        try flow.start()
        for seat in [1, 2, 0, 1] {
            XCTAssertEqual(flow.currentSeat, seat)
            guard case .active(.planning(let progress)) = flow.status else { return XCTFail("Expected planning") }
            XCTAssertEqual(progress.baseAction, .none)
            XCTAssertTrue(progress.shipsExchanged.isEmpty)
            try flow.pass(by: seat)
            try flow.completeTrading(by: seat, action: .deliver, deckCount: 10, handRoom: 2)
        }
        XCTAssertEqual(flow.currentSeat, 2)
        XCTAssertEqual(flow.order.first, 1)
    }

    func testWrongSeatPhaseAndGameLifecycle() throws {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        XCTAssertThrowsError(try flow.pass(by: 1)) { XCTAssertEqual($0 as? TurnFlowError, .notYourTurn) }
        XCTAssertThrowsError(try flow.endPlanning(by: 0)) { XCTAssertEqual($0 as? TurnFlowError, .baseActionRequired) }
        XCTAssertThrowsError(try flow.completeTrading(by: 0, action: .deliver, deckCount: 1, handRoom: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .wrongPhase)
        }
        try flow.pass(by: 0)
        XCTAssertThrowsError(try flow.pass(by: 0)) { XCTAssertEqual($0 as? TurnFlowError, .wrongPhase) }
        XCTAssertThrowsError(try flow.completeTrading(by: 0, action: .skip, deckCount: 1, handRoom: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .skipOnlyWhenDeckEmpty)
        }
        XCTAssertThrowsError(try flow.completeTrading(by: 0, action: .draw, deckCount: 2, handRoom: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .cannotDrawMustDeliver)
        }
        try flow.completeTrading(by: 0, action: .draw, deckCount: 1, handRoom: 1)
        try flow.finish()
        XCTAssertThrowsError(try flow.pass(by: 1)) { XCTAssertEqual($0 as? TurnFlowError, .gameFinished) }
    }

    func testExchangeLimitsAndCraneBuy() throws {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        try flow.exchange(by: 0, ship: 0, cranes: 1)
        XCTAssertThrowsError(try flow.buy(by: 0, kind: .office)) {
            XCTAssertEqual($0 as? TurnFlowError, .baseActionAlreadyTaken)
        }
        XCTAssertThrowsError(try flow.exchange(by: 0, ship: 0, cranes: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .shipAlreadyExchangedThisPhase)
        }
        try flow.exchange(by: 0, ship: 1, cranes: 1)
        XCTAssertThrowsError(try flow.exchange(by: 0, ship: 2, cranes: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .wrongPhase)
        }
        try flow.completeTrading(by: 0, action: .skip, deckCount: 0, handRoom: 0)
        try flow.buy(by: 1, kind: .crane)
        try flow.exchange(by: 1, ship: 0, cranes: 99)
        XCTAssertThrowsError(try flow.exchange(by: 1, ship: 1, cranes: 99)) {
            XCTAssertEqual($0 as? TurnFlowError, .wrongPhase)
        }
    }

    func testBoughtShipEndsPlanningAndRoundTrip() throws {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        try flow.buy(by: 0, kind: .ship, addedShip: 2)
        XCTAssertThrowsError(try flow.exchange(by: 0, ship: 2, cranes: 1)) {
            XCTAssertEqual($0 as? TurnFlowError, .wrongPhase)
        }

        let data = try JSONEncoder().encode(flow)
        XCTAssertEqual(try JSONDecoder().decode(TurnFlow.self, from: data), flow)
        XCTAssertThrowsError(try JSONDecoder().decode(SeatOrder.self, from: Data(#"{"count":0,"first":0}"#.utf8)))
    }

    func testPlanningCanEndWithUnusedCraneExtras() throws {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        try flow.buy(by: 0, kind: .crane)
        try flow.endPlanning(by: 0)
        XCTAssertEqual(flow.status, .active(.trading))
    }

    func testBaseExchangeWithoutCraneEndsPlanning() throws {
        var flow = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try flow.start()
        try flow.exchange(by: 0, ship: 0, cranes: 0)
        XCTAssertEqual(flow.status, .active(.trading))
    }

    func testInvalidRestoredProgressAndSeatAreRejected() throws {
        let decoder = JSONDecoder()
        let badProgress = Data(#"{"baseAction":{"exchange":{}},"shipsExchanged":[],"shipsAddedThisTurn":[],"extrasAllowed":9223372036854775807,"extrasUsed":9223372036854775807}"#.utf8)
        XCTAssertThrowsError(try decoder.decode(PlanningProgress.self, from: badProgress)) {
            XCTAssertEqual($0 as? TurnFlowError, .invalidProgress)
        }
        let badFlow = Data(#"{"order":{"count":2,"first":0},"currentSeat":4,"status":{"notStarted":{}}}"#.utf8)
        XCTAssertThrowsError(try decoder.decode(TurnFlow.self, from: badFlow)) {
            XCTAssertEqual($0 as? TurnFlowError, .invalidProgress)
        }
    }
}
