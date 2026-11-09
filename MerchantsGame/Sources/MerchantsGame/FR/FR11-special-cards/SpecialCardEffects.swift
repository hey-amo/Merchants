public struct SpecialCardEffects: Sendable {
    private let tableau: Tableau
    private let rules: GameRules

    public init(tableau: Tableau, rules: GameRules) {
        self.tableau = tableau
        self.rules = rules
    }

    public var extraExchangesOnExchange: Int { tableau.count(of: .crane) }
    public var freeExchangeOnCraneBuy: Int { 1 }
    public var officeExtraDraws: Int { tableau.count(of: .office) }
    public var handLimitBonus: Int { tableau.count(of: .customsHouse) > 0 ? 2 : 0 }

    public func tradeAgreementBonus(for payout: Int) throws(SpecialCardError) -> Int {
        guard payout >= 0 else { throw .invalidRules }
        guard payout > rules.tradeAgreementMinimumPayout else { return 0 }
        let (bonus, overflow) = tableau.count(of: .tradeAgreement)
            .multipliedReportingOverflow(by: rules.tradeAgreementBonusPerCard)
        guard !overflow else { throw .overflow }
        return bonus
    }
}
