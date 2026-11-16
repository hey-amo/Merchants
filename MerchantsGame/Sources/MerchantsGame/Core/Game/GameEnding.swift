public enum EndGameRule: Codable, Equatable, Sendable {
    case immediate
    case oneMoreTurn
}

public enum GameEndingError: Error, Equatable, Sendable {
    case gameNotOver
    case alreadyTriggered
    case alreadyEnded
    case invalidSeat
    case unexpectedSeat
    case invalidPlayers
}

public struct Standings: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public let player: PlayerID
        public let balance: Coins
    }

    public let entries: [Entry]
    public let winners: [PlayerID]
}

public struct GameEnding: Codable, Equatable, Sendable {
    public enum Status: Codable, Equatable, Sendable {
        case ongoing
        case finalRound(nextSeat: Int)
        case finished
    }

    public let rule: EndGameRule
    public let order: SeatOrder
    public private(set) var status: Status = .ongoing

    public init(rule: EndGameRule, order: SeatOrder) {
        self.rule = rule
        self.order = order
    }

    public func requireActive() throws(GameEndingError) {
        guard status != .finished else { throw .alreadyEnded }
    }

    /// Call once when a trading draw, including Office extras, empties the deck.
    public mutating func deckEmptied(by seat: Int) throws(GameEndingError) {
        try requireActive()
        guard case .ongoing = status else { throw .alreadyTriggered }
        guard (0..<order.count).contains(seat) else { throw .invalidSeat }
        status = rule == .immediate ? .finished : .finalRound(nextSeat: seat)
    }

    /// Call after each completed turn while the final round is active.
    public mutating func turnCompleted(by seat: Int) throws(GameEndingError) {
        try requireActive()
        guard (0..<order.count).contains(seat) else { throw .invalidSeat }
        guard case .finalRound(let expected) = status else { return }
        guard seat == expected else { throw .unexpectedSeat }
        if seat == order.last {
            status = .finished
        } else {
            // The seat has already been checked against this order.
            status = .finalRound(nextSeat: (seat + 1) % order.count)
        }
    }

    public func standings(players: [PlayerID], bank: Bank) throws -> Standings {
        guard status == .finished else { throw GameEndingError.gameNotOver }
        guard players.count == order.count, Set(players).count == players.count,
              Set(players) == Set(bank.standings.keys) else {
            throw GameEndingError.invalidPlayers
        }
        let entries = try players.map { player in
            Standings.Entry(player: player, balance: try bank.balance(of: player))
        }
        let highest = entries.map(\.balance.available).max()
        let winners = entries.filter { $0.balance.available == highest }.map(\.player)
        return Standings(entries: entries, winners: winners)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rule = try container.decode(EndGameRule.self, forKey: .rule)
        let order = try container.decode(SeatOrder.self, forKey: .order)
        let status = try container.decode(Status.self, forKey: .status)
        if case .finalRound(let seat) = status {
            guard rule == .oneMoreTurn, (0..<order.count).contains(seat) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .status, in: container, debugDescription: "Invalid final round."
                )
            }
        }
        self.rule = rule
        self.order = order
        self.status = status
    }

    private enum CodingKeys: String, CodingKey { case rule, order, status }
}
