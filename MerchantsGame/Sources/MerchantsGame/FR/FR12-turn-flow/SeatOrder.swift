public struct SeatOrder: Codable, Equatable, Sendable {
    public let count: Int
    public let first: Int

    public init(count: Int, first: Int) throws(TurnFlowError) {
        guard PlayerCount.range.contains(count), (0..<count).contains(first) else {
            throw .invalidSeating
        }
        self.count = count
        self.first = first
    }

    public var last: Int { (first + count - 1) % count }

    public func next(after seat: Int) throws(TurnFlowError) -> Int {
        guard (0..<count).contains(seat) else { throw .invalidSeating }
        return (seat + 1) % count
    }

    public func draftSeat(at pick: Int) throws(TurnFlowError) -> Int {
        guard (0..<(count * 2)).contains(pick) else { throw .invalidDraftPosition }
        if pick < count {
            return (last - pick + count) % count
        }
        return (first + pick - count) % count
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(count: container.decode(Int.self, forKey: .count),
                      first: container.decode(Int.self, forKey: .first))
    }

    private enum CodingKeys: String, CodingKey { case count, first }
}
