public struct PassiveBot<View, Action>: BotStrategy {
    public init() {}

    public func chooseAction(for view: View, legalActions: [Action]) -> Action? {
        legalActions.first
    }
}
