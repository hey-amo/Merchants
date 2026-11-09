/// Selects an action from candidates supplied by the caller.
public protocol BotStrategy: Sendable {
    /// The observation used to make a decision.
    associatedtype View
    /// An action the strategy can select.
    associatedtype Action

    /// Returns a supplied action, or nil if no action is selected.
    ///
    /// The caller is responsible for supplying legal actions for the observation.
    /// Implementations may decline to select an action, even for a nonempty list.
    func chooseAction(for view: View, legalActions: [Action]) -> Action?
}
