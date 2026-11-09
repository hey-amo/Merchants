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

    func testMaximumBalanceIs5000AndCanBeRestored() throws {
        XCTAssertEqual(Coins.maximumBalance, 5_000)
        XCTAssertEqual(try Coins(5_000).available, 5_000)
        XCTAssertThrowsError(try Coins(5_001)) {
            XCTAssertEqual($0 as? CoinError, .limitExceeded(limit: 5_000, attempted: 5_001))
        }
    }

    func testAddingToMaximumAndPastMaximum() throws {
        var coins = try Coins(4_999)
        try coins.perform(.add(1))
        XCTAssertEqual(coins.available, 5_000)

        XCTAssertThrowsError(try coins.perform(.add(1))) {
            XCTAssertEqual($0 as? CoinError, .limitExceeded(limit: 5_000, attempted: 5_001))
        }
        XCTAssertEqual(coins.available, 5_000)
    }

    func testAddingPastIntMaxFailsAtomically() throws {
        var coins = try Coins(1)

        XCTAssertThrowsError(try coins.perform(.add(Int.max))) {
            XCTAssertEqual($0 as? CoinError, .overflow)
        }

        XCTAssertEqual(coins.available, 1)
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

    func testCodableRejectsBalanceAboveMaximum() {
        let data = Data(#"{"available":5001}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(Coins.self, from: data)) {
            XCTAssertEqual($0 as? CoinError, .limitExceeded(limit: 5_000, attempted: 5_001))
        }
    }
}
