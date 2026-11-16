public enum TransactionReason: Codable, Equatable, Sendable {
    case deliveryPayout(GoodType)
    case tradeAgreementBonus
    case specialCardPurchase(SpecialCardKind)
}
