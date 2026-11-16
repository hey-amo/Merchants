import Foundation
import Testing
@testable import MerchantsGame

@Suite("FR2 game setup randomness")
struct GameSetupRandomnessTests {
    private let players = (0..<4).map { PlayerID("player-\($0)") }

    private func dealtDeck(_ state: GameState) throws -> [GoodsCard] {
        var remainder = state.deck
        let remainingCards = try remainder.draw(remainder.remaining)
        return state.hands.flatMap(\.contents) + state.marketplace.visibleCards + remainingCards
    }

    @Test func seededSetupHasStableDeckAndFirstPlayer() throws {
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        let state = try GameState(configuration: configuration)
        let repeated = try GameState(configuration: configuration)
        let goods: [Character: GoodType] = [
            "S": .sugar, "I": .indigo, "P": .spices,
            "T": .tea, "Y": .silk, "L": .lumber
        ]
        let expected = try "TIIPIPSYPTPPITLTSPPSTIILSLLPYYPYISLYSSYTTTLSPYYTLSSILIYTLLYI".map {
            GoodsCard(good: try #require(goods[$0]))
        }

        #expect(try dealtDeck(state) == expected)
        #expect(try dealtDeck(repeated) == expected)
        #expect(state.draft.order.first == 2)
        #expect(repeated.draft.order.first == state.draft.order.first)
        #expect(state.random.state == 0x15008779D5751516)
        #expect(repeated == state)
    }

    @Test func differentSeedsChangeActualDeck() throws {
        let first = try GameState(configuration: GameConfiguration(playerIDs: players, seed: 1))
        let second = try GameState(configuration: GameConfiguration(playerIDs: players, seed: 2))
        #expect(try dealtDeck(first) != dealtDeck(second))
    }

    @Test func fixedFirstPlayerConsumesNoSelectionRandomness() throws {
        let randomConfig = try GameConfiguration(playerIDs: players, seed: 42)
        let fixedConfig = try GameConfiguration(playerIDs: players, seed: 42, firstPlayer: .fixed(players[3]))
        let random = try GameState(configuration: randomConfig)
        let fixed = try GameState(configuration: fixedConfig)

        #expect(try dealtDeck(random) == dealtDeck(fixed))
        #expect(fixed.draft.order.first == 3)
        #expect(fixed.random.state == 0x76C90DC0562A9901)
        var expected = fixed.random
        _ = expected.next()
        #expect(random.random == expected)
    }

    @Test func restoredStateRetainsRandomnessDuringPlay() throws {
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        var original = try GameState(configuration: configuration)
        let savedRandom = original.random
        var restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(original))
        for _ in 0..<12 {
            let seat = try original.turn?.currentSeat ?? original.draft.nextSeat()
            let player = players[seat]
            let actions = try original.legalActions(for: player)
            let action = try #require(actions.first)
            let (nextOriginal, originalEvents) = try GameEngine.apply(action, by: player, to: original)
            let (nextRestored, restoredEvents) = try GameEngine.apply(action, by: player, to: restored)
            #expect(nextOriginal == nextRestored)
            #expect(originalEvents == restoredEvents)
            #expect(nextOriginal.random == savedRandom)
            original = nextOriginal
            restored = nextRestored
        }
        #expect(original.turn != nil)
    }
}
