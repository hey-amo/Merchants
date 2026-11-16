public struct Hand: Codable, Equatable, Sendable {
    private var cards: [GoodsCard] = []

    public init() {}

    public var count: Int {
        cards.count
    }

    public var contents: [GoodsCard] {
        cards
    }

    public func count(of good: GoodType) -> Int {
        cards.filter { $0.good == good }.count
    }

    public func room(limit: Int) throws(HandError) -> Int {
        guard limit >= 0 else {
            throw .invalidLimit(limit)
        }
        return max(0, limit - count)
    }

    public mutating func add(_ newCards: [GoodsCard], limit: Int) throws(HandError) {
        guard limit >= 0 else {
            throw .invalidLimit(limit)
        }
        let attempted = count + newCards.count
        guard attempted <= limit else {
            throw .limitExceeded(limit: limit, attempted: attempted)
        }
        cards.append(contentsOf: newCards)
    }

    public mutating func remove(good: GoodType, count: Int) throws(HandError) -> [GoodsCard] {
        guard count >= 0 else {
            throw .invalidCount(count)
        }
        let available = self.count(of: good)
        guard count <= available else {
            throw .insufficientCards(good: good, required: count, available: available)
        }
        var removed: [GoodsCard] = []
        var remaining = count
        cards.removeAll { card in
            guard card.good == good, remaining > 0 else { return false }
            remaining -= 1
            removed.append(card)
            return true
        }
        return removed
    }
}
