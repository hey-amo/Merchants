public struct Bank: Codable, Equatable, Sendable {
    private var balances: [PlayerID: Coins]

    public var standings: [PlayerID: Coins] {
        balances
    }

    public init(playerIDs: [PlayerID]) {
        balances = [:]
        for playerID in playerIDs {
            balances[playerID] = try! Coins()
        }
    }

    public init(restoring savedBalances: [PlayerID: Int]) throws(BankingError) {
        var restored: [PlayerID: Coins] = [:]
        for (playerID, amount) in savedBalances {
            do {
                restored[playerID] = try Coins(amount)
            } catch {
                throw .coin(player: error)
            }
        }
        balances = restored
    }

    public func balance(of playerID: PlayerID) throws(BankingError) -> Coins {
        guard let balance = balances[playerID] else {
            throw .unknownPlayer(playerID)
        }
        return balance
    }

    public mutating func apply(_ transactions: [Transaction]) throws(BankingError) {
        var updatedBalances = balances

        for transaction in transactions {
            guard var balance = updatedBalances[transaction.player] else {
                throw .unknownPlayer(transaction.player)
            }

            let action: CoinAction
            switch transaction.direction {
            case .credit:
                action = .add(transaction.amount)
            case .debit:
                action = .subtract(transaction.amount)
            }

            do {
                try balance.perform(action)
            } catch {
                throw .coin(player: error)
            }
            updatedBalances[transaction.player] = balance
        }

        balances = updatedBalances
    }
}
