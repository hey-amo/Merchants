// Deterministic random operations used by game setup.
// Owns the randomness seam, unbiased bounded draws, and Fisher-Yates shuffling.
// Does not create random seeds or store the game state.

public protocol RandomSource: Sendable {
    mutating func next() -> UInt64
}

public extension RandomSource {
    mutating func shuffle<Element>(_ elements: inout [Element]) {
        guard elements.count > 1 else { return }

        for index in stride(from: elements.count - 1, through: 1, by: -1) {
            let swapIndex = Int(next(upperBound: UInt64(index + 1)))
            elements.swapAt(index, swapIndex)
        }
    }

    mutating func firstPlayer(in configuration: GameConfiguration) -> PlayerID {
        switch configuration.firstPlayer {
        case .fixed(let playerID):
            return playerID
        case .random:
            let index = Int(next(upperBound: UInt64(configuration.playerIDs.count)))
            return configuration.playerIDs[index]
        }
    }

    private mutating func next(upperBound: UInt64) -> UInt64 {
        precondition(upperBound > 0)
        let threshold = (0 &- upperBound) % upperBound

        while true {
            let value = next()
            if value >= threshold {
                return value % upperBound
            }
        }
    }
}
