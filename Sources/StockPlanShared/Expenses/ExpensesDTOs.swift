import Foundation

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
