import Foundation

// MARK: - Reports

public struct PillarPlanningSummaryResponse: Codable, Sendable, Equatable {
    public let pillar: BudgetPillar
    public let targetAmount: Double
    public let plannedAmount: Double
    public let actualAmount: Double
    public let unplannedActualAmount: Double

    public init(pillar: BudgetPillar, targetAmount: Double, plannedAmount: Double, actualAmount: Double, unplannedActualAmount: Double) {
        self.pillar = pillar
        self.targetAmount = targetAmount
        self.plannedAmount = plannedAmount
        self.actualAmount = actualAmount
        self.unplannedActualAmount = unplannedActualAmount
    }
}

public struct BudgetMonthSummaryResponse: Codable, Sendable, Equatable {
    public let monthStart: String // YYYY-MM-DD
    public let planned: Double
    public let actual: Double
    public let salary: Double
    public let pillarActuals: [String: Double]
    public let pillarPlans: [String: Double]

    public init(monthStart: String, planned: Double, actual: Double, salary: Double, pillarActuals: [String: Double], pillarPlans: [String: Double]) {
        self.monthStart = monthStart
        self.planned = planned
        self.actual = actual
        self.salary = salary
        self.pillarActuals = pillarActuals
        self.pillarPlans = pillarPlans
    }
}

public struct BudgetYearSummaryResponse: Codable, Sendable, Equatable {
    public let year: Int
    public let planned: Double
    public let actual: Double
    public let salary: Double

    public init(year: Int, planned: Double, actual: Double, salary: Double) {
        self.year = year
        self.planned = planned
        self.actual = actual
        self.salary = salary
    }
}
