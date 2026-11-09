// Stores every configurable rule value used during a game.
// Owns validated rule settings and their backward-compatible Codable form.
// Does not implement game actions or mutate game state.

public struct GameRules: Codable, Equatable, Sendable {
    public static let standard = GameRules()

    public let handLimitBase: Int
    public let specialCardCatalog: SpecialCardCatalog
    public let tradeAgreementBonusPerCard: Int
    public let tradeAgreementMinimumPayout: Int
    public let endGameRule: EndGameRule

    public init() {
        self = try! Self(specialCardCatalog: .standard)
    }

    public init(
        specialCardCatalog: SpecialCardCatalog,
        handLimitBase: Int = 6,
        tradeAgreementBonusPerCard: Int = 2,
        tradeAgreementMinimumPayout: Int = 2,
        endGameRule: EndGameRule = .oneMoreTurn
    ) throws(SpecialCardError) {
        guard handLimitBase >= 3,
              handLimitBase <= Int.max - 2,
              tradeAgreementBonusPerCard >= 0,
              tradeAgreementMinimumPayout >= 0 else {
            throw .invalidRules
        }
        self.handLimitBase = handLimitBase
        self.specialCardCatalog = specialCardCatalog
        self.tradeAgreementBonusPerCard = tradeAgreementBonusPerCard
        self.tradeAgreementMinimumPayout = tradeAgreementMinimumPayout
        self.endGameRule = endGameRule
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = Self.standard
        try self.init(
            specialCardCatalog: container.contains(.specialCardCatalog)
                ? container.decode(SpecialCardCatalog.self, forKey: .specialCardCatalog)
                : standard.specialCardCatalog,
            handLimitBase: container.contains(.handLimitBase)
                ? container.decode(Int.self, forKey: .handLimitBase)
                : standard.handLimitBase,
            tradeAgreementBonusPerCard: container.contains(.tradeAgreementBonusPerCard)
                ? container.decode(Int.self, forKey: .tradeAgreementBonusPerCard)
                : standard.tradeAgreementBonusPerCard,
            tradeAgreementMinimumPayout: container.contains(.tradeAgreementMinimumPayout)
                ? container.decode(Int.self, forKey: .tradeAgreementMinimumPayout)
                : standard.tradeAgreementMinimumPayout,
            endGameRule: container.contains(.endGameRule)
                ? container.decode(EndGameRule.self, forKey: .endGameRule)
                : standard.endGameRule
        )
    }

    private enum CodingKeys: String, CodingKey {
        case specialCardCatalog, handLimitBase, tradeAgreementBonusPerCard
        case tradeAgreementMinimumPayout, endGameRule
    }
}
