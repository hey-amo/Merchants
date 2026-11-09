import Foundation
import XCTest
@testable import MerchantsGame

final class CubeDraftTests: XCTestCase {
    func testDraftAllSeatsAndBeginFirstTurn() throws {
        for count in 2...4 {
            let order = try SeatOrder(count: count, first: 1)
            var draft = CubeDraft(order: order)
            for pick in 0..<(count * 2) {
                let seat = try draft.nextSeat()
                let ship = pick < count ? 0 : 1
                try draft.pick(by: seat, good: pick < 5 ? .tea : .sugar, ship: ship)
            }
            XCTAssertTrue(draft.isComplete)
            for fleet in draft.fleets {
                XCTAssertEqual(fleet.ships.count, 2)
                XCTAssertTrue(fleet.ships.allSatisfy { $0.cubes.count == 1 })
            }
            let flow = try draft.startTurns()
            XCTAssertEqual(flow.currentSeat, 1)
            guard case .active(.planning) = flow.status else { return XCTFail("Expected planning") }
            XCTAssertThrowsError(try draft.nextSeat()) { XCTAssertEqual($0 as? CubeDraftError, .draftComplete) }
        }
    }

    func testSameColourTwiceAndAtomicRejections() throws {
        let order = try SeatOrder(count: 2, first: 0)
        var draft = CubeDraft(order: order)
        let original = draft
        XCTAssertThrowsError(try draft.pick(by: 0, good: .tea, ship: 0)) {
            XCTAssertEqual($0 as? CubeDraftError, .notDraftingSeat)
        }
        XCTAssertThrowsError(try draft.startTurns()) { XCTAssertEqual($0 as? CubeDraftError, .draftNotComplete) }
        XCTAssertEqual(draft, original)
        try draft.pick(by: 1, good: .tea, ship: 0)
        try draft.pick(by: 0, good: .tea, ship: 0)
        let before = draft
        XCTAssertThrowsError(try draft.pick(by: 0, good: .tea, ship: 0)) {
            XCTAssertEqual($0 as? CubeDraftError, .shipNotEmpty)
        }
        XCTAssertThrowsError(try draft.pick(by: 0, good: .tea, ship: 8)) {
            XCTAssertEqual($0 as? CubeDraftError, .ship(.shipNotFound))
        }
        XCTAssertEqual(draft, before)
        try draft.pick(by: 0, good: .tea, ship: 1)
        try draft.pick(by: 1, good: .tea, ship: 1)
        XCTAssertEqual(draft.fleets[0].cubeCount(of: .tea), 2)
    }

    func testUnavailableSupplyIsAtomicAndRestorationResumes() throws {
        var draft = CubeDraft(order: try SeatOrder(count: 4, first: 0))
        for pick in 0..<5 {
            try draft.pick(by: draft.nextSeat(), good: .tea, ship: pick < 4 ? 0 : 1)
        }
        let data = try JSONEncoder().encode(draft)
        var restored = try JSONDecoder().decode(CubeDraft.self, from: data)
        XCTAssertEqual(restored, draft)
        let before = restored
        XCTAssertThrowsError(try restored.pick(by: restored.nextSeat(), good: .tea, ship: 1)) {
            XCTAssertEqual($0 as? CubeDraftError, .supply(.noneAvailable(.tea)))
        }
        XCTAssertEqual(restored, before)
        try restored.pick(by: restored.nextSeat(), good: .silk, ship: 1)
        try draft.pick(by: draft.nextSeat(), good: .silk, ship: 1)
        XCTAssertEqual(restored, draft)
    }

    func testCorruptedDraftRestorationIsRejected() throws {
        let draft = CubeDraft(order: try SeatOrder(count: 2, first: 0))
        let encoded = try JSONEncoder().encode(draft)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["picksMade"] = 1
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try JSONDecoder().decode(CubeDraft.self, from: data)) {
            XCTAssertEqual($0 as? CubeDraftError, .invalidState)
        }
    }
}
