import Foundation

public struct DashboardResponse: Codable, Sendable, Equatable {
    public let totalValue: Double
    public let dailyChange: Double
    public let dailyChangePercent: Double
    public let topPerformers: [DashboardPerformerDTO]
    public let bottomPerformers: [DashboardPerformerDTO]
    public let sectorAllocation: [DashboardAllocationDTO]

    public init(
        totalValue: Double,
        dailyChange: Double,
        dailyChangePercent: Double,
        topPerformers: [DashboardPerformerDTO],
        bottomPerformers: [DashboardPerformerDTO],
        sectorAllocation: [DashboardAllocationDTO]
    ) {
        self.totalValue = totalValue
        self.dailyChange = dailyChange
        self.dailyChangePercent = dailyChangePercent
        self.topPerformers = topPerformers
        self.bottomPerformers = bottomPerformers
        self.sectorAllocation = sectorAllocation
    }
}

public struct DashboardPerformerDTO: Codable, Sendable, Equatable {
    public let symbol: String
    public let change: Double
    public let changePercent: Double

    public init(symbol: String, change: Double, changePercent: Double) {
        self.symbol = symbol
        self.change = change
        self.changePercent = changePercent
    }
}

public struct DashboardAllocationDTO: Codable, Sendable, Equatable {
    public let sector: String
    public let value: Double
    public let percent: Double

    public init(sector: String, value: Double, percent: Double) {
        self.sector = sector
        self.value = value
        self.percent = percent
    }
}

// MARK: - Goals

public struct GoalRequest: Codable, Sendable, Equatable {
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
}

public struct GoalResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(id: String, title: String, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Insights

public struct DashboardInsightsResponse: Codable, Sendable, Equatable {
    public let savingsRate: Double
    public let budgetStreak: Int
    public let watchlistCount: Int
    public let cashBuffer: Double
    
    public init(savingsRate: Double, budgetStreak: Int, watchlistCount: Int, cashBuffer: Double) {
        self.savingsRate = savingsRate
        self.budgetStreak = budgetStreak
        self.watchlistCount = watchlistCount
        self.cashBuffer = cashBuffer
    }
}
