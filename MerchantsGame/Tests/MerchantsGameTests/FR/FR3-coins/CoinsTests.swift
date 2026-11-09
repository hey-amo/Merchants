// Tests FR3 balance validation, atomic operations, and serialization.
// Owns coverage for exact balance boundaries and arithmetic overflow.
// Does not test player, bank, or gameplay-specific coin behavior.

import Foundation
import XCTest
@testable import MerchantsGame

final class CoinsTests: XCTestCase {
    func testInitializesZeroAndPositiveBalances() throws {
        XCTAssertEqual(try Coins().available, 0)
        XCTAssertEqual(try Coins(12).available, 12)
    }

    func testRejectsNegativeInitialBalance() {
        XCTAssertThrowsError(try Coins(-1)) {
            XCTAssertEqual($0 as? CoinError, .isNegativeNumber)
        }
    }

    func testAddsAndSubtractsCoins() throws {
        var coins = try Coins(10)

        try coins.perform(.add(7))
        XCTAssertEqual(coins.available, 17)

        try coins.perform(.subtract(5))
        XCTAssertEqual(coins.available, 12)
    }

    func testZeroActionsAreNoOps() throws {
        var coins = try Coins(4)

        try coins.perform(.add(0))
        XCTAssertEqual(coins.available, 4)

        try coins.perform(.subtract(0))
        XCTAssertEqual(coins.available, 4)
    }

    func testSubtractsExactBalance() throws {
        var coins = try Coins(9)

        try coins.perform(.subtract(9))

        XCTAssertEqual(coins.available, 0)
    }

    func testSubtractingOneMoreThanAvailableFailsAtomically() throws {
        var coins = try Coins(8)

        XCTAssertThrowsError(try coins.perform(.subtract(9))) {
            XCTAssertEqual(
                $0 as? CoinError,
                .insufficientFunds(required: 9, available: 8)
            )
        }

        XCTAssertEqual(coins.available, 8)
    }

    func testNegativeAddFailsAtomically() throws {
        var coins = try Coins(3)

        XCTAssertThrowsError(try coins.perform(.add(-1))) {
            XCTAssertEqual($0 as? CoinError, .isNegativeNumber)
        }

        XCTAssertEqual(coins.available, 3)
    }

    func testNegativeSubtractFailsAtomically() throws {
        var coins = try Coins(3)

        XCTAssertThrowsError(try coins.perform(.subtract(-1))) {
            XCTAssertEqual($0 as? CoinError, .isNegativeNumber)
        }

        XCTAssertEqual(coins.available, 3)
    }

    func testAddingPastIntMaxFailsAtomically() throws {
        var coins = try Coins(Int.max)

        XCTAssertThrowsError(try coins.perform(.add(1))) {
            XCTAssertEqual($0 as? CoinError, .overflow)
        }

        XCTAssertEqual(coins.available, Int.max)
    }

    func testCodableRoundTripsRestoredBalance() throws {
        let coins = try Coins(42)
        let data = try JSONEncoder().encode(coins)
        let restored = try JSONDecoder().decode(Coins.self, from: data)

        XCTAssertEqual(restored, coins)
        XCTAssertEqual(restored.available, 42)
    }

    func testCodableRejectsNegativeBalance() {
        let data = Data(#"{"available":-1}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(Coins.self, from: data)) {
            XCTAssertEqual($0 as? CoinError, .isNegativeNumber)
        }
    }
}
