import Foundation

// MARK: - Pillar Enum

public enum BudgetPillar: String, Codable, Sendable, CaseIterable {
    case fundamentals
    case futureYou
    case fun
}

// MARK: - Budget Snapshot

public struct BudgetSnapshotRequest: Codable, Sendable, Equatable {
    public let monthStart: String // YYYY-MM-DD
    public let netSalary: Double
    public let targetShares: [String: Double] // String key representation of BudgetPillar

    public init(monthStart: String, netSalary: Double, targetShares: [String: Double]) {
        self.monthStart = monthStart
        self.netSalary = netSalary
        self.targetShares = targetShares
    }
}

public struct BudgetSnapshotResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let monthStart: String // YYYY-MM-DD
    public let netSalary: Double
    public let targetShares: [String: Double]
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        monthStart: String,
        netSalary: Double,
        targetShares: [String: Double],
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.monthStart = monthStart
        self.netSalary = netSalary
        self.targetShares = targetShares
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Budget Plan Item

public struct BudgetPlanItemRequest: Codable, Sendable, Equatable {
    public let snapshotId: String
    public let title: String
    public let plannedAmount: Double
    public let pillar: BudgetPillar

    public init(snapshotId: String, title: String, plannedAmount: Double, pillar: BudgetPillar) {
        self.snapshotId = snapshotId
        self.title = title
        self.plannedAmount = plannedAmount
        self.pillar = pillar
    }
}

public struct BudgetPlanItemResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let snapshotId: String
    public let title: String
    public let plannedAmount: Double
    public let pillar: BudgetPillar
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        snapshotId: String,
        title: String,
        plannedAmount: Double,
        pillar: BudgetPillar,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.snapshotId = snapshotId
        self.title = title
        self.plannedAmount = plannedAmount
        self.pillar = pillar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Expense

public struct ExpenseRequest: Codable, Sendable, Equatable {
    public let title: String
    public let amount: Double
    public let pillar: BudgetPillar
    public let occurredOn: String // YYYY-MM-DD
    public let linkedPlanItemId: String?

    public init(title: String, amount: Double, pillar: BudgetPillar, occurredOn: String, linkedPlanItemId: String? = nil) {
        self.title = title
        self.amount = amount
        self.pillar = pillar
        self.occurredOn = occurredOn
        self.linkedPlanItemId = linkedPlanItemId
    }
}

public struct ExpenseResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let amount: Double
    public let pillar: BudgetPillar
    public let occurredOn: String // YYYY-MM-DD
    public let linkedPlanItemId: String?
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        title: String,
        amount: Double,
        pillar: BudgetPillar,
        occurredOn: String,
        linkedPlanItemId: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.pillar = pillar
        self.occurredOn = occurredOn
        self.linkedPlanItemId = linkedPlanItemId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

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
