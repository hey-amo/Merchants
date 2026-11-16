import Testing
@testable import MerchantsGame

@Suite("Bot placeholders")
struct BotPlaceholderTests {
    private struct TestView {
        let player: Int
    }

    enum TestAction: Equatable {
        case draw
        case deliver
        case skip
    }

    @Test(arguments: [
        [TestAction.draw],
        [.deliver, .draw],
        [.skip, .deliver, .draw],
        [.draw, .draw]
    ])
    func passiveBotAlwaysChoosesFirstLegalAction(actions: [TestAction]) throws {
        let bot = PassiveBot<TestView, TestAction>()
        let first = try #require(actions.first)
        let selected = try #require(bot.chooseAction(for: TestView(player: 0), legalActions: actions))
        #expect(selected == first)
        #expect(actions.contains(selected))
        #expect(bot.chooseAction(for: TestView(player: 1), legalActions: actions) == selected)
    }

    @Test func emptyActionsProduceNoSelection() {
        let bot = PassiveBot<TestView, TestAction>()
        #expect(bot.chooseAction(for: TestView(player: 0), legalActions: []) == nil)
    }

    @Test func passiveBotWorksThroughStrategyProtocol() {
        func select<S: BotStrategy>(
            _ strategy: S, view: S.View, actions: [S.Action]
        ) -> S.Action? {
            strategy.chooseAction(for: view, legalActions: actions)
        }

        let selected = select(
            PassiveBot<TestView, TestAction>(), view: TestView(player: 0), actions: [.deliver, .draw]
        )
        #expect(selected == .deliver)
    }
}
