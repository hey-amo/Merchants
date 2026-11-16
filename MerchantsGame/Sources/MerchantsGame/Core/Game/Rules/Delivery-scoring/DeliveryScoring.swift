public enum DeliveryScoringError: Error, Equatable, Sendable {
    case invalidPlayers
    case overflow
    case specialCards(SpecialCardError)
}

public enum DeliveryScoring {
    public static func transactions(
        for good: GoodType,
        marketplace: Marketplace,
        players: [PlayerID],
        fleets: [Fleet],
        tableaux: [Tableau],
        rules: GameRules
    ) throws(DeliveryScoringError) -> [Transaction] {
        guard PlayerCount.range.contains(players.count),
              Set(players).count == players.count,
              fleets.count == players.count, tableaux.count == players.count else {
            throw .invalidPlayers
        }
        let demand = marketplace.demand(for: good)
        var result: [Transaction] = []
        for index in players.indices {
            let (payout, overflow) = fleets[index].cubeCount(of: good).multipliedReportingOverflow(by: demand)
            guard !overflow else { throw .overflow }
            guard payout > 0 else { continue }
            result.append(Transaction(
                player: players[index], amount: payout, direction: .credit, reason: .deliveryPayout(good)
            ))
            let bonus: Int
            do {
                bonus = try SpecialCardEffects(tableau: tableaux[index], rules: rules).tradeAgreementBonus(for: payout)
            } catch {
                throw .specialCards(error)
            }
            if bonus > 0 {
                result.append(Transaction(
                    player: players[index], amount: bonus, direction: .credit, reason: .tradeAgreementBonus
                ))
            }
        }
        return result
    }
}
