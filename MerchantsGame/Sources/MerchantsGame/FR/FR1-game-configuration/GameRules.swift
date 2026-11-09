public struct GameRules: Codable, Equatable, Sendable {
    public static let standard = GameRules()

    public var handLimitBase: Int { 6 }
    public let specialCardCatalog: SpecialCardCatalog
    public let tradeAgreementBonusPerCard: Int
    public let tradeAgreementMinimumPayout: Int

    public init() {
        specialCardCatalog = .standard
        tradeAgreementBonusPerCard = 2
        tradeAgreementMinimumPayout = 2
    }

    public init(
        specialCardCatalog: SpecialCardCatalog,
        tradeAgreementBonusPerCard: Int = 2,
        tradeAgreementMinimumPayout: Int = 2
    ) throws(SpecialCardError) {
        guard tradeAgreementBonusPerCard >= 0, tradeAgreementMinimumPayout >= 0 else {
            throw .invalidRules
        }
        self.specialCardCatalog = specialCardCatalog
        self.tradeAgreementBonusPerCard = tradeAgreementBonusPerCard
        self.tradeAgreementMinimumPayout = tradeAgreementMinimumPayout
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            specialCardCatalog: container.contains(.specialCardCatalog)
                ? container.decode(SpecialCardCatalog.self, forKey: .specialCardCatalog) : .standard,
            tradeAgreementBonusPerCard: container.contains(.tradeAgreementBonusPerCard)
                ? container.decode(Int.self, forKey: .tradeAgreementBonusPerCard) : 2,
            tradeAgreementMinimumPayout: container.contains(.tradeAgreementMinimumPayout)
                ? container.decode(Int.self, forKey: .tradeAgreementMinimumPayout) : 2
        )
    }

    private enum CodingKeys: String, CodingKey {
        case specialCardCatalog, tradeAgreementBonusPerCard, tradeAgreementMinimumPayout
    }
}
