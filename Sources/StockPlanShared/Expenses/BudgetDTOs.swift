import Foundation

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
