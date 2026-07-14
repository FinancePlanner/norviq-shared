import Foundation
import Testing
@testable import StockPlanShared

@Suite("Wealth automation contracts")
struct WealthAutomationDTOTests {
    @Test
    func `forecast derives signed net flow without double counting spending`() throws {
        let defaults = NetWorthForecastDefaults(
            baseCurrency: "EUR",
            monthlyIncome: 4_000,
            monthlySpending: 4_500,
            cashFlowSource: .plannedBudget
        )

        #expect(defaults.monthlyNetFlow == -500)
        let decoded = try JSONDecoder().decode(
            NetWorthForecastDefaults.self,
            from: JSONEncoder().encode(defaults)
        )
        #expect(decoded == defaults)
    }

    @Test
    func `screen conditions distinguish numeric and trend comparisons`() throws {
        try WatchlistScreenCondition(
            id: "margin",
            metric: "net_profit_margin",
            comparison: .improving,
            period: .quarterly
        ).validate()

        #expect(throws: WealthAutomationValidationError.invalidCondition) {
            try WatchlistScreenCondition(
                id: "pe",
                metric: "price_earnings",
                comparison: .lessThan,
                period: .ttm
            ).validate()
        }
    }

    @Test
    func `rebalancing targets must total one hundred percent`() throws {
        let policy = RebalancingPolicy(
            id: "policy",
            portfolioListId: "portfolio",
            cadence: .quarterly,
            driftThreshold: 0.05,
            targets: [
                .init(id: "stock", kind: .symbol, symbol: "ACME", targetWeight: 0.8),
                .init(id: "cash", kind: .cash, targetWeight: 0.2)
            ]
        )
        try policy.validate()

        #expect(throws: WealthAutomationValidationError.invalidAllocation) {
            try RebalancingPolicy(
                id: "invalid",
                portfolioListId: "portfolio",
                cadence: .quarterly,
                targets: [.init(id: "stock", kind: .symbol, symbol: "ACME", targetWeight: 0.8)]
            ).validate()
        }
    }

    @Test
    func `inbox event kinds round trip`() throws {
        let kinds = NotificationEventKind.allCases
        let data = try JSONEncoder().encode(kinds)
        #expect(try JSONDecoder().decode([NotificationEventKind].self, from: data) == kinds)
    }
}
