/// A deterministic placeholder that selects the first supplied action.
public struct PassiveBot<View, Action>: BotStrategy {
    /// Creates a passive strategy.
    public init() {}

    /// Returns the first supplied action, or nil when the list is empty.
    public func chooseAction(for view: View, legalActions: [Action]) -> Action? {
        legalActions.first
    }
}

/// A passive strategy using the game's player view and action types.
public typealias GamePassiveBot = PassiveBot<PlayerView, GameAction>
