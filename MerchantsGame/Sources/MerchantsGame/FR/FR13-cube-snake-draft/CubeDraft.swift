public enum CubeDraftError: Error, Equatable, Sendable {
    case notDraftingSeat
    case shipNotEmpty
    case draftComplete
    case draftNotComplete
    case ship(ShipError)
    case supply(CubeSupplyError)
    case invalidState
}

public struct CubeDraft: Codable, Equatable, Sendable {
    public let order: SeatOrder
    public private(set) var fleets: [Fleet]
    public private(set) var supply: CubeSupply
    public private(set) var picksMade: Int

    public init(order: SeatOrder) {
        self.order = order
        fleets = Array(repeating: Fleet(), count: order.count)
        supply = CubeSupply()
        picksMade = 0
    }

    public var isComplete: Bool { picksMade == order.count * 2 }

    public func nextSeat() throws(CubeDraftError) -> Int {
        guard !isComplete else { throw .draftComplete }
        do { return try order.draftSeat(at: picksMade) }
        catch { throw .invalidState }
    }

    public mutating func pick(by seat: Int, good: GoodType, ship: Int) throws(CubeDraftError) {
        guard seat == (try nextSeat()) else { throw .notDraftingSeat }
        guard fleets[seat].ships.indices.contains(ship) else { throw .ship(.shipNotFound) }
        guard fleets[seat].ships[ship].cubes.isEmpty else { throw .shipNotEmpty }
        var updatedSupply = supply
        var updatedFleet = fleets[seat]
        let cube: GoodsCube
        do { cube = try updatedSupply.take(good) }
        catch { throw .supply(error) }
        do { try updatedFleet.load(cube, onto: ship) }
        catch { throw .ship(error) }
        supply = updatedSupply
        fleets[seat] = updatedFleet
        picksMade += 1
    }

    public func startTurns() throws(CubeDraftError) -> TurnFlow {
        guard isComplete else { throw .draftNotComplete }
        var flow = TurnFlow(order: order)
        do { try flow.start() }
        catch { throw .invalidState }
        return flow
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let order = try c.decode(SeatOrder.self, forKey: .order)
        let fleets = try c.decode([Fleet].self, forKey: .fleets)
        let supply = try c.decode(CubeSupply.self, forKey: .supply)
        let picks = try c.decode(Int.self, forKey: .picksMade)
        guard fleets.count == order.count, (0...(order.count * 2)).contains(picks) else {
            throw CubeDraftError.invalidState
        }
        var expected = Array(repeating: 0, count: order.count)
        for pick in 0..<picks {
            let seat = try order.draftSeat(at: pick)
            expected[seat] += 1
        }
        for seat in 0..<order.count {
            let ships = fleets[seat].ships
            guard ships.count == 2, ships.allSatisfy({ $0.kind == .standard }),
                  ships.reduce(0, { $0 + $1.cubes.count }) == expected[seat] else {
                throw CubeDraftError.invalidState
            }
        }
        for good in GoodType.allCases {
            let onShips = fleets.reduce(0) { $0 + $1.cubeCount(of: good) }
            guard supply.available(of: good) + onShips == CubeSupply.cubesPerGood else {
                throw CubeDraftError.invalidState
            }
        }
        self.order = order
        self.fleets = fleets
        self.supply = supply
        picksMade = picks
    }
    private enum CodingKeys: String, CodingKey { case order, fleets, supply, picksMade }
}
