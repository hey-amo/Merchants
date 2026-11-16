public struct SpecialCardStock: Codable, Equatable, Sendable {
    public let catalog: SpecialCardCatalog
    public let playerCount: Int
    private var remaining: [SpecialCardKind: Int]

    public init(playerCount: Int, catalog: SpecialCardCatalog) throws(SpecialCardError) {
        guard (2...4).contains(playerCount) else { throw .invalidPlayerCount }
        self.catalog = catalog
        self.playerCount = playerCount
        var counts: [SpecialCardKind: Int] = [:]
        for kind in SpecialCardKind.allCases {
            counts[kind] = try catalog.stock(for: kind, playerCount: playerCount)
        }
        remaining = counts
    }

    public func available(of kind: SpecialCardKind) -> Int {
        remaining[kind]!
    }

    public mutating func purchase(_ kind: SpecialCardKind, for tableau: inout Tableau) throws(SpecialCardError) {
        guard available(of: kind) > 0 else { throw .outOfStock(kind) }
        if let limit = catalog.entry(for: kind).ownershipLimit, tableau.count(of: kind) >= limit {
            throw .ownershipLimitReached(kind)
        }
        try tableau.add(kind)
        remaining[kind]! -= 1
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let catalog = try container.decode(SpecialCardCatalog.self, forKey: .catalog)
        let playerCount = try container.decode(Int.self, forKey: .playerCount)
        let remaining = try container.decode([SpecialCardKind: Int].self, forKey: .remaining)
        guard (2...4).contains(playerCount),
              Set(remaining.keys) == Set(SpecialCardKind.allCases) else {
            throw SpecialCardError.invalidStock
        }
        for kind in SpecialCardKind.allCases {
            let maximum = try catalog.stock(for: kind, playerCount: playerCount)
            guard let count = remaining[kind],
                  (0...maximum).contains(count) else {
                throw SpecialCardError.invalidStock
            }
        }
        self.catalog = catalog
        self.playerCount = playerCount
        self.remaining = remaining
    }

    private enum CodingKeys: String, CodingKey { case catalog, playerCount, remaining }
}
