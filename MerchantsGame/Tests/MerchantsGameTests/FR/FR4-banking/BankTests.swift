import Foundation
import XCTest
@testable import MerchantsGame

final class BankTests: XCTestCase {
    private let alice = PlayerID("alice")
    private let bob = PlayerID("bob")

    func testInitializesPlayersWithZeroBalances() throws {
        let bank = Bank(playerIDs: [alice, bob])

        XCTAssertEqual(try bank.balance(of: alice), try Coins())
        XCTAssertEqual(try bank.balance(of: bob), try Coins())
    }

    func testCreditsAndDebitsCoins() throws {
        var bank = Bank(playerIDs: [alice])

        try bank.apply([
            Transaction(
                player: alice,
                amount: 12,
                direction: .credit,
                reason: .deliveryPayout(.sugar)
            )
        ])
        try bank.apply([
            Transaction(
                player: alice,
                amount: 5,
                direction: .debit,
                reason: .specialCardPurchase(.ship)
            )
        ])

        XCTAssertEqual(try bank.balance(of: alice), try Coins(7))
    }

    func testBatchWithFailingLastDebitLeavesAllBalancesUnchanged() throws {
        var bank = try Bank(restoring: [alice: 5, bob: 2])
        let originalStandings = bank.standings

        XCTAssertThrowsError(
            try bank.apply([
                Transaction(
                    player: alice,
                    amount: 3,
                    direction: .credit,
                    reason: .tradeAgreementBonus
                ),
                Transaction(
                    player: bob,
                    amount: 3,
                    direction: .debit,
                    reason: .specialCardPurchase(.largeShip)
                )
            ])
        ) {
            XCTAssertEqual(
                $0 as? BankingError,
                .coin(player: .insufficientFunds(required: 3, available: 2))
            )
        }

        XCTAssertEqual(bank.standings, originalStandings)
    }

    func testUnknownPlayersAreRejectedForTransactionsAndBalanceLookups() throws {
        var bank = Bank(playerIDs: [alice])
        let unknownPlayer = PlayerID("unknown")

        XCTAssertThrowsError(try bank.balance(of: unknownPlayer)) {
            XCTAssertEqual($0 as? BankingError, .unknownPlayer(unknownPlayer))
        }
        XCTAssertThrowsError(
            try bank.apply([
                Transaction(
                    player: unknownPlayer,
                    amount: 1,
                    direction: .credit,
                    reason: .tradeAgreementBonus
                )
            ])
        ) {
            XCTAssertEqual($0 as? BankingError, .unknownPlayer(unknownPlayer))
        }
    }

    func testTransactionReasonsArePreserved() throws {
        let transactions = [
            Transaction(
                player: alice,
                amount: 3,
                direction: .credit,
                reason: .deliveryPayout(.indigo)
            ),
            Transaction(
                player: bob,
                amount: 4,
                direction: .credit,
                reason: .tradeAgreementBonus
            ),
            Transaction(
                player: alice,
                amount: 2,
                direction: .debit,
                reason: .specialCardPurchase(.customsHouse)
            )
        ]
        var bank = Bank(playerIDs: [alice, bob])

        try bank.apply(transactions)

        XCTAssertEqual(
            try bank.balance(of: alice),
            try Coins(1)
        )
        XCTAssertEqual(
            try bank.balance(of: bob),
            try Coins(4)
        )
        XCTAssertEqual(
            try JSONDecoder().decode(
                [Transaction].self,
                from: JSONEncoder().encode(transactions)
            ),
            transactions
        )
    }

    func testRestoresValidBalancesAndRejectsNegativeBalances() throws {
        let bank = try Bank(restoring: [alice: 9, bob: 0])

        XCTAssertEqual(try bank.balance(of: alice), try Coins(9))
        XCTAssertEqual(try bank.balance(of: bob), try Coins())
        XCTAssertThrowsError(try Bank(restoring: [alice: -1])) {
            XCTAssertEqual($0 as? BankingError, .coin(player: .isNegativeNumber))
        }
        XCTAssertThrowsError(try Bank(restoring: [alice: 5_001])) {
            XCTAssertEqual(
                $0 as? BankingError,
                .coin(player: .limitExceeded(limit: Coins.maximumBalance, attempted: 5_001))
            )
        }
    }

    func testStandingsIsAReadOnlySnapshot() throws {
        let bank = Bank(playerIDs: [alice])
        var snapshot = bank.standings
        snapshot[alice] = try Coins(99)

        XCTAssertEqual(try bank.balance(of: alice), try Coins())
    }

    func testBankCodableRoundTripsValidatedBalances() throws {
        let bank = try Bank(restoring: [alice: 11, bob: 6])
        let data = try JSONEncoder().encode(bank)
        let restored = try JSONDecoder().decode(Bank.self, from: data)

        XCTAssertEqual(restored, bank)
    }

    func testBatchExceedingMaximumBalanceFailsAtomically() throws {
        var bank = try Bank(restoring: [alice: 4_999, bob: 2])
        let originalStandings = bank.standings

        XCTAssertThrowsError(
            try bank.apply([
                Transaction(
                    player: bob,
                    amount: 3,
                    direction: .credit,
                    reason: .tradeAgreementBonus
                ),
                Transaction(
                    player: alice,
                    amount: 2,
                    direction: .credit,
                    reason: .deliveryPayout(.sugar)
                )
            ])
        ) {
            XCTAssertEqual(
                $0 as? BankingError,
                .coin(player: .limitExceeded(limit: Coins.maximumBalance, attempted: 5_001))
            )
        }
        XCTAssertEqual(bank.standings, originalStandings)
    }

    func testMaximumBalanceIsAcceptedAndOverflowIsPreserved() throws {
        var bank = try Bank(restoring: [alice: Coins.maximumBalance])

        XCTAssertEqual(try bank.balance(of: alice), try Coins(5_000))
        XCTAssertThrowsError(
            try bank.apply([
                Transaction(
                    player: alice,
                    amount: Int.max,
                    direction: .credit,
                    reason: .tradeAgreementBonus
                )
            ])
        ) {
            XCTAssertEqual($0 as? BankingError, .coin(player: .overflow))
        }
        XCTAssertEqual(try bank.balance(of: alice), try Coins(5_000))
    }
}
