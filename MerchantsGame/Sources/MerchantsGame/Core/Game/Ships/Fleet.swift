public struct Fleet: Codable, Equatable, Sendable {
    public private(set) var ships: [Ship]

    public init() {
        ships = [Ship(kind: .standard), Ship(kind: .standard)]
    }

    public mutating func load(_ cube: GoodsCube, onto shipIndex: Int) throws(ShipError) {
        guard ships.indices.contains(shipIndex) else { throw .shipNotFound }
        try ships[shipIndex].load(cube)
    }

    public mutating func exchange(
        shipIndex: Int,
        cubeIndex: Int,
        for cube: GoodsCube
    ) throws(ShipError) -> GoodsCube {
        guard ships.indices.contains(shipIndex) else { throw .shipNotFound }
        return try ships[shipIndex].exchange(cubeIndex: cubeIndex, for: cube)
    }

    public mutating func addShip(kind: Ship.Kind) {
        ships.append(Ship(kind: kind))
    }

    public func cubeCount(of good: GoodType) -> Int {
        ships.reduce(0) { count, ship in
            count + ship.cubes.filter { $0.good == good }.count
        }
    }
}
