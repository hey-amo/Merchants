// Coordinates planning actions on copies of the existing domain owners.
// The caller commits the returned state only after the whole action succeeds.
// Does not own game setup, trading, scoring, or the live game store.

public enum PlanningAction: Equatable, Sendable {
    case exchange(ship: Int, cubeIndex: Int, good: GoodType)
    case buy(SpecialCardKind, loadCubes: [GoodType])
    case pass
    case endPlanning
}

public enum PlanningError: Error, Equatable, Sendable {
    case invalidState
    case unknownPlayer
    case invalidShipLoad
    case turn(TurnFlowError)
    case banking(BankingError)
    case supply(CubeSupplyError)
    case ship(ShipError)
    case specialCard(SpecialCardError)
}

public struct PlanningState: Equatable, Sendable {
    public let players: [PlayerID]
    public let rules: GameRules
    public var turn: TurnFlow
    public var bank: Bank
    public var supply: CubeSupply
    public var fleets: [Fleet]
    public var stock: SpecialCardStock
    public var tableaus: [Tableau]

    public init(
        players: [PlayerID], rules: GameRules, turn: TurnFlow, bank: Bank,
        supply: CubeSupply, fleets: [Fleet], stock: SpecialCardStock, tableaus: [Tableau]
    ) throws(PlanningError) {
        guard players.count == turn.order.count, Set(players).count == players.count,
              fleets.count == players.count, tableaus.count == players.count,
              Set(bank.standings.keys) == Set(players),
              stock.playerCount == players.count, stock.catalog == rules.specialCardCatalog else {
            throw .invalidState
        }
        self.players = players
        self.rules = rules
        self.turn = turn
        self.bank = bank
        self.supply = supply
        self.fleets = fleets
        self.stock = stock
        self.tableaus = tableaus
    }
}

public enum PlanningPhaseRules {
    public static func apply(
        _ action: PlanningAction, by player: PlayerID, to state: PlanningState
    ) throws(PlanningError) -> PlanningState {
        guard let seat = state.players.firstIndex(of: player) else { throw .unknownPlayer }
        guard state.players.count == state.turn.order.count, Set(state.players).count == state.players.count,
              state.fleets.count == state.players.count, state.tableaus.count == state.players.count,
              Set(state.bank.standings.keys) == Set(state.players),
              state.stock.playerCount == state.players.count,
              state.stock.catalog == state.rules.specialCardCatalog else { throw .invalidState }
        var result = state
        switch action {
        case .pass:
            do { try result.turn.pass(by: seat) } catch { throw .turn(error) }
        case .endPlanning:
            do { try result.turn.endPlanning(by: seat) } catch { throw .turn(error) }
        case .exchange(let ship, let cubeIndex, let good):
            let cranes = SpecialCardEffects(tableau: result.tableaus[seat], rules: result.rules)
                .extraExchangesOnExchange
            do { try result.turn.exchange(by: seat, ship: ship, cranes: cranes) }
            catch { throw .turn(error) }
            guard result.fleets[seat].ships.indices.contains(ship) else { throw .ship(.shipNotFound) }
            let shipValue = result.fleets[seat].ships[ship]
            guard shipValue.cubes.indices.contains(cubeIndex) else { throw .ship(.cubeIndexOutOfRange) }
            guard shipValue.cubes[cubeIndex].good != good else { throw .ship(.sameGood) }
            let cube: GoodsCube
            do { cube = try result.supply.take(good) } catch { throw .supply(error) }
            let removed: GoodsCube
            do { removed = try result.fleets[seat].exchange(shipIndex: ship, cubeIndex: cubeIndex, for: cube) }
            catch { throw .ship(error) }
            do { try result.supply.returnCube(removed) } catch { throw .supply(error) }
            try finishIfNoExchangePossible(seat: seat, state: &result)
        case .buy(let kind, let goods):
            let capacity: Int
            switch kind {
            case .ship: capacity = Ship.Kind.standard.capacity
            case .largeShip: capacity = Ship.Kind.large.capacity
            default: capacity = 0
            }
            guard kind == .largeShip ? (1...capacity).contains(goods.count) : goods.count == capacity else {
                throw .invalidShipLoad
            }
            let shipIndex = capacity > 0 ? result.fleets[seat].ships.count : nil
            do { try result.turn.buy(by: seat, kind: kind, addedShip: shipIndex) }
            catch { throw .turn(error) }
            let price = result.rules.specialCardCatalog.entry(for: kind).price
            let debit = Transaction(player: player, amount: price, direction: .debit, reason: .specialCardPurchase(kind))
            do { try result.bank.apply([debit]) } catch { throw .banking(error) }
            do { try result.stock.purchase(kind, for: &result.tableaus[seat]) }
            catch { throw .specialCard(error) }
            if let shipIndex {
                result.fleets[seat].addShip(kind: kind == .ship ? .standard : .large)
                for good in goods {
                    let cube: GoodsCube
                    do { cube = try result.supply.take(good) } catch { throw .supply(error) }
                    do { try result.fleets[seat].load(cube, onto: shipIndex) }
                    catch { throw .ship(error) }
                }
            }
            try finishIfNoExchangePossible(seat: seat, state: &result)
        }
        return result
    }

    private static func finishIfNoExchangePossible(seat: Int, state: inout PlanningState) throws(PlanningError) {
        guard case .active(.planning(let progress)) = state.turn.status,
              progress.baseAction != .none else { return }
        let possible = state.fleets[seat].ships.enumerated().contains { index, ship in
            !progress.shipsExchanged.contains(index) && !progress.shipsAddedThisTurn.contains(index) &&
                ship.cubes.contains { cube in
                    GoodType.allCases.contains { $0 != cube.good && state.supply.available(of: $0) > 0 }
                }
        }
        if !possible {
            do { try state.turn.endPlanning(by: seat) } catch { throw .turn(error) }
        }
    }
}
