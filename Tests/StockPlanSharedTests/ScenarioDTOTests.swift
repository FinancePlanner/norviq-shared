import Foundation
import Testing
@testable import StockPlanShared

@Suite("Scenario contracts")
struct ScenarioDTOTests {
    @Test
    func `all supported asset categories remain codable`() throws {
        let data = try JSONEncoder().encode(AssetCategory.allCases)
        let decoded = try JSONDecoder().decode([AssetCategory].self, from: data)
        #expect(decoded == [.stock, .etf, .mutualFund, .crypto, .cash, .bond, .realEstate, .commodity])
    }

    @Test(arguments: [
        ScenarioConfiguration.historical(.init(catalogId: "covid_crash")),
        ScenarioConfiguration.custom(.init(horizonMonths: 12)),
        ScenarioConfiguration.monteCarlo(.init(horizonMonths: 360))
    ])
    func `tagged configurations round trip`(_ configuration: ScenarioConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(ScenarioConfiguration.self, from: data) == configuration)
    }

    @Test
    func `monte carlo validation enforces documented limits`() {
        #expect(throws: ScenarioValidationError.invalidPathCount) {
            try ScenarioConfiguration.monteCarlo(.init(pathCount: 50_001, horizonMonths: 360)).validate()
        }
        #expect(throws: ScenarioValidationError.invalidHorizon) {
            try ScenarioConfiguration.monteCarlo(.init(horizonMonths: 601)).validate()
        }
        #expect(throws: ScenarioValidationError.invalidDegreesOfFreedom) {
            try ScenarioConfiguration.monteCarlo(
                .init(distribution: .studentT, horizonMonths: 120, degreesOfFreedom: 2)
            ).validate()
        }
    }

    @Test
    func `comparison accepts at most four results`() {
        let result = ScenarioResult(id: "result", runId: "run", timeline: [], maximumDrawdown: 0)
        #expect(throws: ScenarioValidationError.tooManyComparisons) {
            _ = try ScenarioComparison(results: Array(repeating: result, count: 5))
        }
    }
}
