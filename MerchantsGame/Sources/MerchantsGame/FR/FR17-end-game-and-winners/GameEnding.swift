// Tracks the deck-empty trigger and final-round completion.
// Determines when the game ends, without choosing actions or mutating balances.
// Winner calculation and session orchestration belong to the game engine.

public enum EndGameRule: Codable, Equatable, Sendable {
    case immediate
    case oneMoreTurn
}

public enum GameEndingError: Error, Equatable, Sendable {
    case alreadyTriggered
    case alreadyEnded
    case invalidSeat
}

public struct GameEnding: Codable, Equatable, Sendable {
    public enum Status: Codable, Equatable, Sendable {
        case ongoing
        case finalRound
        case finished
    }

    public let rule: EndGameRule
    public let order: SeatOrder
    public private(set) var status: Status = .ongoing

    public init(rule: EndGameRule, order: SeatOrder) {
        self.rule = rule
        self.order = order
    }

    public mutating func deckEmptied() throws(GameEndingError) {
        switch status {
        case .ongoing:
            status = rule == .immediate ? .finished : .finalRound
        case .finalRound:
            throw .alreadyTriggered
        case .finished:
            throw .alreadyEnded
        }
    }

    public mutating func turnCompleted(by seat: Int) throws(GameEndingError) {
        guard (0..<order.count).contains(seat) else { throw .invalidSeat }
        guard status != .finished else { throw .alreadyEnded }
        if status == .finalRound && seat == order.last {
            status = .finished
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rule = try container.decode(EndGameRule.self, forKey: .rule)
        order = try container.decode(SeatOrder.self, forKey: .order)
        status = try container.decode(Status.self, forKey: .status)
        guard rule == .oneMoreTurn || status != .finalRound else {
            throw DecodingError.dataCorruptedError(
                forKey: .status, in: container,
                debugDescription: "Immediate games cannot have a final round."
            )
        }
    }

    private enum CodingKeys: String, CodingKey { case rule, order, status }
}
