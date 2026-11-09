// Minimal rules value needed by game configuration.
// FR25 will add tunable settings and define the standard rules.
// This type does not implement or apply game mechanics.

public struct GameRules: Codable, Equatable, Sendable {
    public static let standard = GameRules()

    public var handLimitBase: Int { 6 }

    public init() {}
}
