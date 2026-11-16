public enum SpecialCardError: Error, Equatable, Sendable {
    case outOfStock(SpecialCardKind)
    case ownershipLimitReached(SpecialCardKind)
    case invalidCatalog
    case invalidPlayerCount
    case invalidStock
    case invalidTableau
    case invalidRules
    case overflow
}
