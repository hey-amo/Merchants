import Foundation
import XCTest
@testable import MerchantsGame

final class CubeSupplyTests: XCTestCase {
    func testStandardSupplyHasFiveCubesOfEveryGood() {
        let supply = CubeSupply()

        XCTAssertEqual(CubeSupply.cubesPerGood, 5)
        for good in GoodType.allCases {
            XCTAssertEqual(supply.available(of: good), 5)
        }
        XCTAssertEqual(GoodType.allCases.reduce(0) { $0 + supply.available(of: $1) }, 30)
    }

    func testTakesAllFiveCubesOfEveryGoodAndRejectsTheSixthAtomically() throws {
        var supply = CubeSupply()

        for good in GoodType.allCases {
            for _ in 0..<CubeSupply.cubesPerGood {
                XCTAssertEqual(try supply.take(good), GoodsCube(good: good))
            }
            XCTAssertEqual(supply.available(of: good), 0)
            let original = supply
            XCTAssertThrowsError(try supply.take(good)) {
                XCTAssertEqual($0 as? CubeSupplyError, .noneAvailable(good))
            }
            XCTAssertEqual(supply, original)
        }
    }

    func testReturningCubesRestoresOnlyTheirGood() throws {
        var supply = CubeSupply()

        for good in GoodType.allCases {
            let cube = try supply.take(good)
            XCTAssertEqual(supply.available(of: good), 4)
            try supply.returnCube(cube)
            XCTAssertEqual(supply.available(of: good), 5)
        }
    }

    func testReturningToFullSupplyFailsAtomicallyForEveryGood() {
        var supply = CubeSupply()
        let original = supply

        for good in GoodType.allCases {
            XCTAssertThrowsError(try supply.returnCube(GoodsCube(good: good))) {
                XCTAssertEqual($0 as? CubeSupplyError, .supplyFull(good))
            }
            XCTAssertEqual(supply, original)
        }
    }

    func testRestorationAcceptsBothLimitsForEveryGood() throws {
        for good in GoodType.allCases {
            var zeroCounts = Dictionary(uniqueKeysWithValues: GoodType.allCases.map { ($0, 5) })
            zeroCounts[good] = 0
            XCTAssertEqual(try CubeSupply(restoring: zeroCounts).available(of: good), 0)

            var fullCounts = Dictionary(uniqueKeysWithValues: GoodType.allCases.map { ($0, 0) })
            fullCounts[good] = 5
            XCTAssertEqual(try CubeSupply(restoring: fullCounts).available(of: good), 5)
        }
    }

    func testRestorationRejectsCountsOutsideLimits() {
        for good in GoodType.allCases {
            for invalidCount in [-1, CubeSupply.cubesPerGood + 1] {
                var counts = Dictionary(uniqueKeysWithValues: GoodType.allCases.map { ($0, 5) })
                counts[good] = invalidCount
                XCTAssertThrowsError(try CubeSupply(restoring: counts)) {
                    XCTAssertEqual(
                        $0 as? CubeSupplyError,
                        .invalidCount(good: good, count: invalidCount)
                    )
                }
            }
        }
    }

    func testRestorationRejectsMissingGoodCount() {
        var counts = Dictionary(uniqueKeysWithValues: GoodType.allCases.map { ($0, 5) })
        counts.removeValue(forKey: .silk)

        XCTAssertThrowsError(try CubeSupply(restoring: counts)) {
            XCTAssertEqual($0 as? CubeSupplyError, .missingCount(.silk))
        }
    }

    func testCodableRoundTripPreservesAllGoodCounts() throws {
        var supply = CubeSupply()
        for (index, good) in GoodType.allCases.enumerated() {
            for _ in 0..<index {
                _ = try supply.take(good)
            }
        }

        let data = try JSONEncoder().encode(supply)
        let restored = try JSONDecoder().decode(CubeSupply.self, from: data)

        XCTAssertEqual(restored, supply)
        for good in GoodType.allCases {
            XCTAssertEqual(restored.available(of: good), supply.available(of: good))
        }
    }

    func testCodableRejectsInvalidCountsForEveryGood() {
        for good in GoodType.allCases {
            for invalidCount in [-1, CubeSupply.cubesPerGood + 1] {
                let counts = GoodType.allCases.map { candidate in
                    "\"\(candidate)\":\(candidate == good ? invalidCount : 5)"
                }.joined(separator: ",")
                let data = Data("{\(counts)}".utf8)

                XCTAssertThrowsError(try JSONDecoder().decode(CubeSupply.self, from: data)) {
                    XCTAssertEqual(
                        $0 as? CubeSupplyError,
                        .invalidCount(good: good, count: invalidCount)
                    )
                }
            }
        }
    }

    func testCodableRejectsMissingGoodForEveryGood() {
        for missingGood in GoodType.allCases {
            let counts = GoodType.allCases
                .filter { $0 != missingGood }
                .map { "\"\($0)\":5" }
                .joined(separator: ",")
            let data = Data("{\(counts)}".utf8)

            XCTAssertThrowsError(try JSONDecoder().decode(CubeSupply.self, from: data)) {
                XCTAssertEqual($0 as? CubeSupplyError, .missingCount(missingGood))
            }
        }
    }
}
