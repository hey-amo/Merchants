// Shared good vocabulary used by cards, cubes, and transaction reasons.
// Colour mapping belongs to the presentation layer.

public enum GoodType: CaseIterable, Codable, Sendable, Comparable {
    case sugar
    case indigo
    case spices
    case tea
    case silk
    case lumber

    public static func < (lhs: Self, rhs: Self) -> Bool {
        func order(of good: Self) -> Int {
            switch good {
            case .sugar: 0
            case .indigo: 1
            case .spices: 2
            case .tea: 3
            case .silk: 4
            case .lumber: 5
            }
        }

        return order(of: lhs) < order(of: rhs)
    }
}
