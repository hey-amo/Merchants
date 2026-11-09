public struct PlanningProgress: Codable, Equatable, Sendable {
    public enum BaseAction: Codable, Equatable, Sendable {
        case none
        case exchange
        case buy(SpecialCardKind)
        case pass
    }

    public private(set) var baseAction: BaseAction = .none
    public private(set) var shipsExchanged: Set<Int> = []
    public private(set) var shipsAddedThisTurn: Set<Int> = []
    public private(set) var extrasAllowed = 0
    public private(set) var extrasUsed = 0

    fileprivate init() {}

    fileprivate var valid: Bool {
        guard extrasAllowed >= 0, extrasUsed >= 0, extrasUsed <= extrasAllowed,
              shipsExchanged.allSatisfy({ $0 >= 0 }), shipsAddedThisTurn.allSatisfy({ $0 >= 0 }),
              shipsExchanged.isDisjoint(with: shipsAddedThisTurn) else { return false }
        switch baseAction {
        case .none, .pass:
            return shipsExchanged.isEmpty && shipsAddedThisTurn.isEmpty && extrasAllowed == 0 && extrasUsed == 0
        case .exchange:
            return shipsAddedThisTurn.isEmpty && !shipsExchanged.isEmpty && extrasUsed == shipsExchanged.count - 1
        case .buy(let kind):
            return shipsExchanged.count == extrasUsed &&
                (kind == .crane ? extrasAllowed == 1 : extrasAllowed == 0) &&
                (kind == .ship || kind == .largeShip ? shipsAddedThisTurn.count == 1 : shipsAddedThisTurn.isEmpty)
        }
    }

    fileprivate mutating func exchange(ship: Int, cranes: Int) throws(TurnFlowError) {
        guard ship >= 0, cranes >= 0 else { throw .invalidProgress }
        guard !shipsAddedThisTurn.contains(ship) else { throw .shipAddedThisTurn }
        guard !shipsExchanged.contains(ship) else { throw .shipAlreadyExchangedThisPhase }
        if baseAction == .none {
            baseAction = .exchange
            extrasAllowed = cranes
        } else {
            guard extrasUsed < extrasAllowed else { throw .noExtraExchangeAvailable }
            extrasUsed += 1
        }
        shipsExchanged.insert(ship)
    }

    fileprivate mutating func buy(_ kind: SpecialCardKind, addedShip: Int?) throws(TurnFlowError) {
        guard baseAction == .none else { throw .baseActionAlreadyTaken }
        if let addedShip {
            guard addedShip >= 0, kind == .ship || kind == .largeShip else { throw .invalidProgress }
            shipsAddedThisTurn.insert(addedShip)
        } else if kind == .ship || kind == .largeShip {
            throw .invalidProgress
        }
        baseAction = .buy(kind)
        extrasAllowed = kind == .crane ? 1 : 0
    }

    fileprivate mutating func pass() throws(TurnFlowError) {
        guard baseAction == .none else { throw .baseActionAlreadyTaken }
        baseAction = .pass
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        baseAction = try c.decode(BaseAction.self, forKey: .baseAction)
        shipsExchanged = try c.decode(Set<Int>.self, forKey: .shipsExchanged)
        shipsAddedThisTurn = try c.decode(Set<Int>.self, forKey: .shipsAddedThisTurn)
        extrasAllowed = try c.decode(Int.self, forKey: .extrasAllowed)
        extrasUsed = try c.decode(Int.self, forKey: .extrasUsed)
        guard valid else { throw TurnFlowError.invalidProgress }
    }
    private enum CodingKeys: String, CodingKey {
        case baseAction, shipsExchanged, shipsAddedThisTurn, extrasAllowed, extrasUsed
    }
}

public enum TurnPhase: Codable, Equatable, Sendable {
    case planning(PlanningProgress)
    case trading
}

public struct TurnFlow: Codable, Equatable, Sendable {
    public enum Status: Codable, Equatable, Sendable {
        case notStarted
        case active(TurnPhase)
        case finished
    }

    public let order: SeatOrder
    public private(set) var currentSeat: Int
    public private(set) var status: Status

    public init(order: SeatOrder) {
        self.order = order
        currentSeat = order.first
        status = .notStarted
    }

    public mutating func start() throws(TurnFlowError) {
        guard status == .notStarted else { throw .phaseAlreadyCompleted }
        status = .active(.planning(PlanningProgress()))
    }

    public mutating func exchange(by seat: Int, ship: Int, cranes: Int) throws(TurnFlowError) {
        var progress = try planning(by: seat)
        try progress.exchange(ship: ship, cranes: cranes)
        status = progress.extrasUsed == progress.extrasAllowed ? .active(.trading) : .active(.planning(progress))
    }

    public mutating func buy(by seat: Int, kind: SpecialCardKind, addedShip: Int? = nil) throws(TurnFlowError) {
        var progress = try planning(by: seat)
        try progress.buy(kind, addedShip: addedShip)
        status = progress.extrasAllowed == 0 ? .active(.trading) : .active(.planning(progress))
    }

    public mutating func pass(by seat: Int) throws(TurnFlowError) {
        var progress = try planning(by: seat)
        try progress.pass()
        status = .active(.trading)
    }

    public mutating func endPlanning(by seat: Int) throws(TurnFlowError) {
        let progress = try planning(by: seat)
        guard progress.baseAction != .none else { throw .baseActionRequired }
        status = .active(.trading)
    }

    public enum TradingAction: Sendable { case deliver, draw, skip }

    public mutating func completeTrading(by seat: Int, action: TradingAction, deckCount: Int, handRoom: Int) throws(TurnFlowError) {
        try validateTurn(seat)
        guard status == .active(.trading) else { throw .wrongPhase }
        guard deckCount >= 0, handRoom >= 0 else { throw .invalidProgress }
        switch action {
        case .deliver: break
        case .draw:
            guard deckCount > 0, handRoom >= min(2, deckCount) else { throw .cannotDrawMustDeliver }
        case .skip:
            guard deckCount == 0 else { throw .skipOnlyWhenDeckEmpty }
        }
        currentSeat = try order.next(after: currentSeat)
        status = .active(.planning(PlanningProgress()))
    }

    public mutating func finish() throws(TurnFlowError) {
        guard case .active = status else {
            if status == .finished { throw .gameFinished }
            throw .gameNotStarted
        }
        status = .finished
    }

    private func validateTurn(_ seat: Int) throws(TurnFlowError) {
        switch status {
        case .notStarted: throw .gameNotStarted
        case .finished: throw .gameFinished
        case .active: break
        }
        guard seat == currentSeat else { throw .notYourTurn }
    }

    private func planning(by seat: Int) throws(TurnFlowError) -> PlanningProgress {
        try validateTurn(seat)
        guard case .active(.planning(let progress)) = status else { throw .wrongPhase }
        return progress
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let order = try c.decode(SeatOrder.self, forKey: .order)
        let seat = try c.decode(Int.self, forKey: .currentSeat)
        let status = try c.decode(Status.self, forKey: .status)
        guard (0..<order.count).contains(seat), status != .notStarted || seat == order.first else {
            throw TurnFlowError.invalidProgress
        }
        if case .active(.planning(let progress)) = status, progress.baseAction != .none,
           progress.extrasUsed == progress.extrasAllowed {
            throw TurnFlowError.invalidProgress
        }
        self.order = order
        currentSeat = seat
        self.status = status
    }
    private enum CodingKeys: String, CodingKey { case order, currentSeat, status }
}
