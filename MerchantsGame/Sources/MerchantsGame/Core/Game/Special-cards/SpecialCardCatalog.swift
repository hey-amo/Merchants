public struct SpecialCardCatalog: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public let price: Int
        public let stockByPlayerCount: [Int]
        public let ownershipLimit: Int?

        public init(price: Int, stockByPlayerCount: [Int], ownershipLimit: Int?) throws(SpecialCardError) {
            guard price >= 0, stockByPlayerCount.count == 3,
                  stockByPlayerCount.allSatisfy({ $0 >= 0 }),
                  ownershipLimit.map({ $0 > 0 }) ?? true else {
                throw .invalidCatalog
            }
            self.price = price
            self.stockByPlayerCount = stockByPlayerCount
            self.ownershipLimit = ownershipLimit
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            try self.init(
                price: container.decode(Int.self, forKey: .price),
                stockByPlayerCount: container.decode([Int].self, forKey: .stockByPlayerCount),
                ownershipLimit: container.decodeIfPresent(Int.self, forKey: .ownershipLimit)
            )
        }

        private enum CodingKeys: String, CodingKey {
            case price, stockByPlayerCount, ownershipLimit
        }
    }

    private let entries: [SpecialCardKind: Entry]

    public init(entries: [SpecialCardKind: Entry]) throws(SpecialCardError) {
        guard Set(entries.keys) == Set(SpecialCardKind.allCases) else { throw .invalidCatalog }
        self.entries = entries
    }

    public static let standard: Self = {
        // Literal values are the validated standard catalog in PRD section 4.2.
        try! Self(entries: [
            .ship: Entry(price: 10, stockByPlayerCount: [10, 8, 6], ownershipLimit: nil),
            .largeShip: Entry(price: 18, stockByPlayerCount: [2, 3, 4], ownershipLimit: 1),
            .office: Entry(price: 8, stockByPlayerCount: [2, 2, 2], ownershipLimit: nil),
            .crane: Entry(price: 12, stockByPlayerCount: [2, 2, 2], ownershipLimit: nil),
            .tradeAgreement: Entry(price: 11, stockByPlayerCount: [2, 2, 2], ownershipLimit: nil),
            .customsHouse: Entry(price: 8, stockByPlayerCount: [2, 3, 4], ownershipLimit: 1)
        ])
    }()

    public func entry(for kind: SpecialCardKind) -> Entry {
        entries[kind]!
    }

    public func stock(for kind: SpecialCardKind, playerCount: Int) throws(SpecialCardError) -> Int {
        guard (2...4).contains(playerCount) else { throw .invalidPlayerCount }
        return entry(for: kind).stockByPlayerCount[playerCount - 2]
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(entries: container.decode([SpecialCardKind: Entry].self, forKey: .entries))
    }

    private enum CodingKeys: String, CodingKey { case entries }
}
