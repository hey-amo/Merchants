// Special-card vocabulary used by transaction reasons.

public enum SpecialCardKind: Codable, Hashable, CaseIterable, Sendable {
    case ship
    case largeShip
    case office
    case crane
    case tradeAgreement
    case customsHouse
}
