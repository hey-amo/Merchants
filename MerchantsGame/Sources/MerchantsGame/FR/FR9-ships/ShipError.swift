public enum ShipError: Error, Equatable, Sendable {
    case shipNotFound
    case cubeIndexOutOfRange
    case capacityExceeded
    case sameGood
}
