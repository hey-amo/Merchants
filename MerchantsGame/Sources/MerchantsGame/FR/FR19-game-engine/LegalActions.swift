extension GameState {
    public func legalActions(for player: PlayerID) throws(EngineError) -> [GameAction] {
        guard ending.status != .finished,
              let seat = configuration.playerIDs.firstIndex(of: player) else { return [] }
        var candidates: [GameAction] = []
        if let turn {
            guard turn.currentSeat == seat, case .active = turn.status else { return [] }
        } else {
            let nextSeat: Int
            do {
                nextSeat = try draft.nextSeat()
            } catch {
                throw .draft(error)
            }
            guard nextSeat == seat else { return [] }
        }
        if turn == nil {
            for ship in fleets[seat].ships.indices {
                for good in GoodType.allCases {
                    candidates.append(.draftCube(good: good, ship: ship))
                }
            }
        } else {
            candidates.append(contentsOf: [.passPlanning, .endPlanning, .drawCards, .skipTrading])
            for (ship, value) in fleets[seat].ships.enumerated() {
                for index in value.cubes.indices {
                    for good in GoodType.allCases {
                        candidates.append(.exchangeCube(ship: ship, cubeIndex: index, good: good))
                    }
                }
            }
            for kind in SpecialCardKind.allCases {
                switch kind {
                case .ship:
                    for good in GoodType.allCases {
                        candidates.append(.buySpecialCard(kind: kind, loadCubes: [good]))
                    }
                case .largeShip:
                    for first in GoodType.allCases {
                        for second in GoodType.allCases {
                            candidates.append(.buySpecialCard(kind: kind, loadCubes: [first, second]))
                        }
                    }
                default: candidates.append(.buySpecialCard(kind: kind, loadCubes: []))
                }
            }
            for good in GoodType.allCases {
                let count = min(hands[seat].count(of: good), Marketplace.slotCount)
                guard count > 0 else { continue }
                func placements(_ selected: [Int]) {
                    if !selected.isEmpty {
                        candidates.append(.deliverCards(selected.map {
                            DeliveryPlacement(slot: $0, card: GoodsCard(good: good))
                        }))
                    }
                    guard selected.count < count else { return }
                    for slot in 0..<Marketplace.slotCount where !selected.contains(slot) {
                        placements(selected + [slot])
                    }
                }
                placements([])
            }
        }
        var legal: [GameAction] = []
        for candidate in candidates {
            do {
                _ = try GameEngine.apply(candidate, by: player, to: self)
                legal.append(candidate)
            } catch {
                switch error.error {
                case .unexpected, .planning(.invalidState), .trading(.invalidPlayerState), .deliveryScoring:
                    throw error.error
                default: continue
                }
            }
        }
        return legal
    }
}
