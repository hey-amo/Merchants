import Foundation
import XCTest
@testable import MerchantsGame

final class FleetTests: XCTestCase {
    func testStartingFleetAndCapacity() throws {
        var fleet = Fleet()
        XCTAssertEqual(fleet.ships.map(\.kind), [.standard, .standard])
        XCTAssertTrue(fleet.ships.allSatisfy { $0.cubes.isEmpty })
        try fleet.load(GoodsCube(good: .sugar), onto: 0)
        let original = fleet
        XCTAssertThrowsError(try fleet.load(GoodsCube(good: .tea), onto: 0)) {
            XCTAssertEqual($0 as? ShipError, .capacityExceeded)
        }
        XCTAssertEqual(fleet, original)
    }

    func testLargeShipHoldsTwoAndCountsGoodsAcrossFleet() throws {
        var fleet = Fleet()
        fleet.addShip(kind: .large)
        try fleet.load(GoodsCube(good: .tea), onto: 0)
        try fleet.load(GoodsCube(good: .sugar), onto: 2)
        try fleet.load(GoodsCube(good: .tea), onto: 2)
        XCTAssertEqual(fleet.cubeCount(of: .tea), 2)
        XCTAssertEqual(fleet.cubeCount(of: .sugar), 1)
        XCTAssertEqual(fleet.cubeCount(of: .silk), 0)
        XCTAssertThrowsError(try fleet.load(GoodsCube(good: .silk), onto: 2)) {
            XCTAssertEqual($0 as? ShipError, .capacityExceeded)
        }
    }

    func testExchangeEachLargeShipSlotAndRejectSameGood() throws {
        var fleet = Fleet()
        fleet.addShip(kind: .large)
        try fleet.load(GoodsCube(good: .sugar), onto: 2)
        try fleet.load(GoodsCube(good: .tea), onto: 2)
        for index in 0...1 {
            let good = fleet.ships[2].cubes[index].good
            let original = fleet
            XCTAssertThrowsError(try fleet.exchange(shipIndex: 2, cubeIndex: index, for: GoodsCube(good: good))) {
                XCTAssertEqual($0 as? ShipError, .sameGood)
            }
            XCTAssertEqual(fleet, original)
            XCTAssertEqual(try fleet.exchange(shipIndex: 2, cubeIndex: index, for: GoodsCube(good: .silk)), GoodsCube(good: good))
        }
        XCTAssertEqual(fleet.cubeCount(of: .silk), 2)
    }

    func testInvalidIndicesAreRejectedAtomically() throws {
        var fleet = Fleet()
        let original = fleet
        for index in [-1, 2] {
            XCTAssertThrowsError(try fleet.load(GoodsCube(good: .tea), onto: index)) {
                XCTAssertEqual($0 as? ShipError, .shipNotFound)
            }
            XCTAssertThrowsError(try fleet.exchange(shipIndex: index, cubeIndex: 0, for: GoodsCube(good: .tea))) {
                XCTAssertEqual($0 as? ShipError, .shipNotFound)
            }
        }
        XCTAssertThrowsError(try fleet.exchange(shipIndex: 0, cubeIndex: -1, for: GoodsCube(good: .tea))) {
            XCTAssertEqual($0 as? ShipError, .cubeIndexOutOfRange)
        }
        XCTAssertEqual(fleet, original)
    }

    func testCodableRoundTripAndOverCapacityRejection() throws {
        var fleet = Fleet()
        try fleet.load(GoodsCube(good: .sugar), onto: 0)
        let data = try JSONEncoder().encode(fleet)
        XCTAssertEqual(try JSONDecoder().decode(Fleet.self, from: data), fleet)
        let invalid = Data(#"{"kind":{"standard":{}},"cubes":[{"good":{"sugar":{}}},{"good":{"tea":{}}}]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Ship.self, from: invalid)) {
            XCTAssertEqual($0 as? ShipError, .capacityExceeded)
        }
    }
}
