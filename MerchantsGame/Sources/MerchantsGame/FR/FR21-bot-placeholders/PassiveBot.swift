public struct PassiveBot<View, Action>: BotStrategy {
    public init() {}

    public func chooseAction(for view: View, legalActions: [Action]) -> Action? {
        legalActions.first
    }

}

public typealias GamePassiveBot = PassiveBot<PlayerView, GameAction>
