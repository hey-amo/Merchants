public enum GameAction: Codable, Equatable, Sendable {
    case draftCube(good: GoodType, ship: Int)
    case exchangeCube(ship: Int, cubeIndex: Int, good: GoodType)
    case buySpecialCard(kind: SpecialCardKind, loadCubes: [GoodType])
    case passPlanning
    case endPlanning
    case deliverCards([DeliveryPlacement])
    case drawCards
    case skipTrading
}
