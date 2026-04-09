import Foundation

// MARK: - Pillar Enum

public enum BudgetPillar: String, Codable, Sendable, CaseIterable {
    case fundamentals
    case futureYou
    case fun
}

public enum ExpenseSplitMode: String, Codable, Sendable, CaseIterable {
    case personal
    case shared
}

public struct HouseholdPartnerProfileResponse: Codable, Sendable, Equatable {
    public let displayName: String?

    public init(displayName: String? = nil) {
        self.displayName = displayName
    }
}

public struct HouseholdPartnerProfileRequest: Codable, Sendable, Equatable {
    public let displayName: String?

    public init(displayName: String? = nil) {
        self.displayName = displayName
    }

    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

// MARK: - Budget Snapshot

public struct BudgetSnapshotRequest: Codable, Sendable, Equatable {
    public let monthStart: String  // YYYY-MM-DD
    public let netSalary: Double
    public let targetShares: [String: Double]  // String key representation of BudgetPillar

    public init(monthStart: String, netSalary: Double, targetShares: [String: Double]) {
        self.monthStart = monthStart
        self.netSalary = netSalary
        self.targetShares = targetShares
    }
}

public struct BudgetSnapshotResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let monthStart: String  // YYYY-MM-DD
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

    private enum CodingKeys: String, CodingKey {
        case id
        case monthStart = "month_start"
        case netSalary = "net_salary"
        case targetShares = "target_shares"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Budget Plan Item

public struct BudgetPlanItemRequest: Codable, Sendable, Equatable {
    public let snapshotId: String
    public let title: String
    public let plannedAmount: Double
    public let pillar: BudgetPillar
    public let splitMode: ExpenseSplitMode
    public let userSharePercent: Double

    private enum CodingKeys: String, CodingKey {
        case snapshotId
        case title
        case plannedAmount
        case pillar
        case splitMode
        case userSharePercent
    }

    public init(
        snapshotId: String,
        title: String,
        plannedAmount: Double,
        pillar: BudgetPillar,
        splitMode: ExpenseSplitMode = .personal,
        userSharePercent: Double = 100
    ) {
        self.snapshotId = snapshotId
        self.title = title
        self.plannedAmount = plannedAmount
        self.pillar = pillar
        self.splitMode = splitMode
        self.userSharePercent = userSharePercent
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.snapshotId = try container.decode(String.self, forKey: .snapshotId)
        self.title = try container.decode(String.self, forKey: .title)
        self.plannedAmount = try container.decode(Double.self, forKey: .plannedAmount)
        self.pillar = try container.decode(BudgetPillar.self, forKey: .pillar)
        self.splitMode = try container.decodeIfPresent(ExpenseSplitMode.self, forKey: .splitMode) ?? .personal
        self.userSharePercent = try container.decodeIfPresent(Double.self, forKey: .userSharePercent) ?? 100
    }
}

public struct BudgetPlanItemResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let snapshotId: String
    public let title: String
    public let plannedAmount: Double
    public let pillar: BudgetPillar
    public let splitMode: ExpenseSplitMode
    public let userSharePercent: Double
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        snapshotId: String,
        title: String,
        plannedAmount: Double,
        pillar: BudgetPillar,
        splitMode: ExpenseSplitMode = .personal,
        userSharePercent: Double = 100,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.snapshotId = snapshotId
        self.title = title
        self.plannedAmount = plannedAmount
        self.pillar = pillar
        self.splitMode = splitMode
        self.userSharePercent = userSharePercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case snapshotId = "snapshot_id"
        case title
        case plannedAmount = "planned_amount"
        case pillar
        case splitMode = "split_mode"
        case userSharePercent = "user_share_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Expense

public struct ExpenseRequest: Codable, Sendable, Equatable {
    public let title: String
    public let amount: Double
    public let pillar: BudgetPillar
    public let occurredOn: String  // YYYY-MM-DD
    public let linkedPlanItemId: String?
    public let splitMode: ExpenseSplitMode
    public let userSharePercent: Double

    private enum CodingKeys: String, CodingKey {
        case title
        case amount
        case pillar
        case occurredOn
        case linkedPlanItemId
        case splitMode
        case userSharePercent
    }

    public init(
        title: String,
        amount: Double,
        pillar: BudgetPillar,
        occurredOn: String,
        linkedPlanItemId: String? = nil,
        splitMode: ExpenseSplitMode = .personal,
        userSharePercent: Double = 100
    ) {
        self.title = title
        self.amount = amount
        self.pillar = pillar
        self.occurredOn = occurredOn
        self.linkedPlanItemId = linkedPlanItemId
        self.splitMode = splitMode
        self.userSharePercent = userSharePercent
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.pillar = try container.decode(BudgetPillar.self, forKey: .pillar)
        self.occurredOn = try container.decode(String.self, forKey: .occurredOn)
        self.linkedPlanItemId = try container.decodeIfPresent(String.self, forKey: .linkedPlanItemId)
        self.splitMode = try container.decodeIfPresent(ExpenseSplitMode.self, forKey: .splitMode) ?? .personal
        self.userSharePercent = try container.decodeIfPresent(Double.self, forKey: .userSharePercent) ?? 100
    }
}

public struct ExpenseResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let amount: Double
    public let pillar: BudgetPillar
    public let occurredOn: String  // YYYY-MM-DD
    public let linkedPlanItemId: String?
    public let splitMode: ExpenseSplitMode
    public let userSharePercent: Double
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        title: String,
        amount: Double,
        pillar: BudgetPillar,
        occurredOn: String,
        linkedPlanItemId: String? = nil,
        splitMode: ExpenseSplitMode = .personal,
        userSharePercent: Double = 100,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.pillar = pillar
        self.occurredOn = occurredOn
        self.linkedPlanItemId = linkedPlanItemId
        self.splitMode = splitMode
        self.userSharePercent = userSharePercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case pillar
        case occurredOn = "occurred_on"
        case linkedPlanItemId = "linked_plan_item_id"
        case splitMode = "split_mode"
        case userSharePercent = "user_share_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Reports

public struct PillarPlanningSummaryResponse: Codable, Sendable, Equatable {
    public let pillar: BudgetPillar
    public let targetAmount: Double
    public let plannedAmount: Double
    public let actualAmount: Double
    public let unplannedActualAmount: Double

    public init(
        pillar: BudgetPillar, targetAmount: Double, plannedAmount: Double, actualAmount: Double,
        unplannedActualAmount: Double
    ) {
        self.pillar = pillar
        self.targetAmount = targetAmount
        self.plannedAmount = plannedAmount
        self.actualAmount = actualAmount
        self.unplannedActualAmount = unplannedActualAmount
    }

    private enum CodingKeys: String, CodingKey {
        case pillar
        case targetAmount = "target_amount"
        case plannedAmount = "planned_amount"
        case actualAmount = "actual_amount"
        case unplannedActualAmount = "unplanned_actual_amount"
    }
}

public struct BudgetMonthSummaryResponse: Codable, Sendable, Equatable {
    public let monthStart: String  // YYYY-MM-DD
    public let planned: Double
    public let actual: Double
    public let salary: Double
    public let myPlanned: Double
    public let partnerPlanned: Double
    public let myActual: Double
    public let partnerActual: Double
    public let pillarActuals: [String: Double]
    public let pillarPlans: [String: Double]
    public let myPillarActuals: [String: Double]
    public let partnerPillarActuals: [String: Double]
    public let myPillarPlans: [String: Double]
    public let partnerPillarPlans: [String: Double]

    public init(
        monthStart: String,
        planned: Double,
        actual: Double,
        salary: Double,
        myPlanned: Double = 0,
        partnerPlanned: Double = 0,
        myActual: Double = 0,
        partnerActual: Double = 0,
        pillarActuals: [String: Double],
        pillarPlans: [String: Double],
        myPillarActuals: [String: Double] = [:],
        partnerPillarActuals: [String: Double] = [:],
        myPillarPlans: [String: Double] = [:],
        partnerPillarPlans: [String: Double] = [:]
    ) {
        self.monthStart = monthStart
        self.planned = planned
        self.actual = actual
        self.salary = salary
        self.myPlanned = myPlanned
        self.partnerPlanned = partnerPlanned
        self.myActual = myActual
        self.partnerActual = partnerActual
        self.pillarActuals = pillarActuals
        self.pillarPlans = pillarPlans
        self.myPillarActuals = myPillarActuals
        self.partnerPillarActuals = partnerPillarActuals
        self.myPillarPlans = myPillarPlans
        self.partnerPillarPlans = partnerPillarPlans
    }

    private enum CodingKeys: String, CodingKey {
        case monthStart = "month_start"
        case planned
        case actual
        case salary
        case myPlanned = "my_planned"
        case partnerPlanned = "partner_planned"
        case myActual = "my_actual"
        case partnerActual = "partner_actual"
        case pillarActuals = "pillar_actuals"
        case pillarPlans = "pillar_plans"
        case myPillarActuals = "my_pillar_actuals"
        case partnerPillarActuals = "partner_pillar_actuals"
        case myPillarPlans = "my_pillar_plans"
        case partnerPillarPlans = "partner_pillar_plans"
    }
}

public struct BudgetYearSummaryResponse: Codable, Sendable, Equatable {
    public let year: Int
    public let planned: Double
    public let actual: Double
    public let salary: Double
    public let myPlanned: Double
    public let partnerPlanned: Double
    public let myActual: Double
    public let partnerActual: Double

    public init(
        year: Int,
        planned: Double,
        actual: Double,
        salary: Double,
        myPlanned: Double = 0,
        partnerPlanned: Double = 0,
        myActual: Double = 0,
        partnerActual: Double = 0
    ) {
        self.year = year
        self.planned = planned
        self.actual = actual
        self.salary = salary
        self.myPlanned = myPlanned
        self.partnerPlanned = partnerPlanned
        self.myActual = myActual
        self.partnerActual = partnerActual
    }

    private enum CodingKeys: String, CodingKey {
        case year
        case planned
        case actual
        case salary
        case myPlanned = "my_planned"
        case partnerPlanned = "partner_planned"
        case myActual = "my_actual"
        case partnerActual = "partner_actual"
    }
}

public struct ReportsCashFlowPointResponse: Codable, Sendable, Equatable, Identifiable {
    public var id: String { monthStart }
    public let monthStart: String
    public let income: Double
    public let expenses: Double
    public let net: Double
    public let savingsRate: Double

    public init(
        monthStart: String,
        income: Double,
        expenses: Double,
        net: Double,
        savingsRate: Double
    ) {
        self.monthStart = monthStart
        self.income = income
        self.expenses = expenses
        self.net = net
        self.savingsRate = savingsRate
    }

    private enum CodingKeys: String, CodingKey {
        case monthStart = "month_start"
        case income
        case expenses
        case net
        case savingsRate = "savings_rate"
    }
}

public struct ReportsOverviewResponse: Codable, Sendable, Equatable {
    public let generatedAt: String
    public let portfolioStatistics: ImportedStocksStatisticsDTO
    public let monthlySummaries: [BudgetMonthSummaryResponse]
    public let yearlySummaries: [BudgetYearSummaryResponse]
    public let latestMonthSummary: BudgetMonthSummaryResponse?
    public let latestPillarSummaries: [PillarPlanningSummaryResponse]
    public let cashFlow: [ReportsCashFlowPointResponse]

    public init(
        generatedAt: String,
        portfolioStatistics: ImportedStocksStatisticsDTO,
        monthlySummaries: [BudgetMonthSummaryResponse],
        yearlySummaries: [BudgetYearSummaryResponse],
        latestMonthSummary: BudgetMonthSummaryResponse?,
        latestPillarSummaries: [PillarPlanningSummaryResponse],
        cashFlow: [ReportsCashFlowPointResponse]
    ) {
        self.generatedAt = generatedAt
        self.portfolioStatistics = portfolioStatistics
        self.monthlySummaries = monthlySummaries
        self.yearlySummaries = yearlySummaries
        self.latestMonthSummary = latestMonthSummary
        self.latestPillarSummaries = latestPillarSummaries
        self.cashFlow = cashFlow
    }

    private enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case portfolioStatistics = "portfolio_statistics"
        case monthlySummaries = "monthly_summaries"
        case yearlySummaries = "yearly_summaries"
        case latestMonthSummary = "latest_month_summary"
        case latestPillarSummaries = "latest_pillar_summaries"
        case cashFlow = "cash_flow"
    }
}

public enum ReportSuggestionSeverity: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
}

public enum ReportSuggestionCategory: String, Codable, Sendable, CaseIterable {
    case overspend
    case unplannedSpend
    case savingsTrend
}

public struct ReportSuggestionResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let message: String
    public let severity: ReportSuggestionSeverity
    public let category: ReportSuggestionCategory
    public let monthStart: String
    public let recommendedSavings: Double
    public let detailPayload: [String: String]

    public init(
        id: String,
        title: String,
        message: String,
        severity: ReportSuggestionSeverity,
        category: ReportSuggestionCategory,
        monthStart: String,
        recommendedSavings: Double,
        detailPayload: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.category = category
        self.monthStart = monthStart
        self.recommendedSavings = recommendedSavings
        self.detailPayload = detailPayload
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case severity
        case category
        case monthStart = "month_start"
        case recommendedSavings = "recommended_savings"
        case detailPayload = "detail_payload"
    }
}

public struct ReportSuggestionsResponse: Codable, Sendable, Equatable {
    public let generatedAt: String
    public let suggestions: [ReportSuggestionResponse]

    public init(generatedAt: String, suggestions: [ReportSuggestionResponse]) {
        self.generatedAt = generatedAt
        self.suggestions = suggestions
    }

    private enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case suggestions
    }
}
