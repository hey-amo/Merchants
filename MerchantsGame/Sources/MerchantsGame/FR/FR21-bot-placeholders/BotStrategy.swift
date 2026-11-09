public protocol BotStrategy: Sendable {
    associatedtype View
    associatedtype Action

    func chooseAction(for view: View, legalActions: [Action]) -> Action?
}
