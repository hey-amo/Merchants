public struct DrawDeck: Codable, Equatable, Sendable {
    private var cards: [GoodsCard]

    public var remaining: Int {
        cards.count
    }

    public var isEmpty: Bool {
        cards.isEmpty
    }

    func count(of good: GoodType) -> Int {
        cards.filter { $0.good == good }.count
    }

    public init(cards: [GoodsCard]) {
        self.cards = cards
    }

    public mutating func draw(_ count: Int) throws(DrawDeckError) -> [GoodsCard] {
        guard count >= 0 else {
            throw .invalidCount
        }
        guard !cards.isEmpty else {
            throw .empty
        }

        let drawnCount = min(count, cards.count)
        let drawn = Array(cards.prefix(drawnCount))
        cards.removeFirst(drawnCount)
        return drawn
    }
}
