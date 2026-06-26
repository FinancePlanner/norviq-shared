import Foundation

public struct AllocationItem: Codable, Sendable, Equatable {
    public let symbol: String
    public let value: Double
    public let currency: String

    public init(symbol: String, value: Double, currency: String) {
        self.symbol = symbol
        self.value = value
        self.currency = currency
    }
}

public struct PortfolioSummaryResponse: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let totalValue: Double
    public let totalCost: Double
    public let unrealizedPnl: Double
    public let realizedPnl: Double
    public let cashBalance: Double
    public let allocation: [AllocationItem]

    public init(
        baseCurrency: String,
        totalValue: Double,
        totalCost: Double,
        unrealizedPnl: Double,
        realizedPnl: Double,
        cashBalance: Double = 0,
        allocation: [AllocationItem]
    ) {
        self.baseCurrency = baseCurrency
        self.totalValue = totalValue
        self.totalCost = totalCost
        self.unrealizedPnl = unrealizedPnl
        self.realizedPnl = realizedPnl
        self.cashBalance = cashBalance
        self.allocation = allocation
    }

    enum CodingKeys: String, CodingKey {
        case baseCurrency
        case totalValue
        case totalCost
        case unrealizedPnl
        case realizedPnl
        case cashBalance
        case allocation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseCurrency = try container.decode(String.self, forKey: .baseCurrency)
        totalValue = try container.decode(Double.self, forKey: .totalValue)
        totalCost = try container.decode(Double.self, forKey: .totalCost)
        unrealizedPnl = try container.decode(Double.self, forKey: .unrealizedPnl)
        realizedPnl = try container.decode(Double.self, forKey: .realizedPnl)
        cashBalance = try container.decodeIfPresent(Double.self, forKey: .cashBalance) ?? 0
        allocation = try container.decode([AllocationItem].self, forKey: .allocation)
    }
}

public struct PerformancePoint: Codable, Sendable, Equatable {
    public let date: String
    public let value: Double

    public init(date: String, value: Double) {
        self.date = date
        self.value = value
    }
}

public struct PortfolioPerformanceResponse: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let points: [PerformancePoint]

    public init(baseCurrency: String, points: [PerformancePoint]) {
        self.baseCurrency = baseCurrency
        self.points = points
    }
}

public struct PortfolioSectorHoldingContribution: Codable, Sendable, Equatable, Identifiable {
    public var id: String { symbol }
    public let symbol: String
    public let value: Double
    public let weightPercent: Double

    public init(symbol: String, value: Double, weightPercent: Double) {
        self.symbol = symbol
        self.value = value
        self.weightPercent = weightPercent
    }
}

public struct PortfolioSectorExposureItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String { sector }
    public let sector: String
    public let value: Double
    public let weightPercent: Double
    public let benchmarkWeightPercent: Double?
    public let overweightPercent: Double?
    public let holdings: [PortfolioSectorHoldingContribution]

    public init(
        sector: String,
        value: Double,
        weightPercent: Double,
        benchmarkWeightPercent: Double?,
        overweightPercent: Double?,
        holdings: [PortfolioSectorHoldingContribution]
    ) {
        self.sector = sector
        self.value = value
        self.weightPercent = weightPercent
        self.benchmarkWeightPercent = benchmarkWeightPercent
        self.overweightPercent = overweightPercent
        self.holdings = holdings
    }
}

public struct PortfolioSectorExposureResponse: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let totalValue: Double
    public let investedValue: Double
    public let cashBalance: Double
    public let benchmarkName: String
    public let benchmarkAsOf: String
    public let sectors: [PortfolioSectorExposureItem]

    public init(
        baseCurrency: String,
        totalValue: Double,
        investedValue: Double,
        cashBalance: Double,
        benchmarkName: String,
        benchmarkAsOf: String,
        sectors: [PortfolioSectorExposureItem]
    ) {
        self.baseCurrency = baseCurrency
        self.totalValue = totalValue
        self.investedValue = investedValue
        self.cashBalance = cashBalance
        self.benchmarkName = benchmarkName
        self.benchmarkAsOf = benchmarkAsOf
        self.sectors = sectors
    }
}

public struct SectorGainItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String { sector }
    public let sector: String
    public let marketValue: Double
    public let costBasis: Double
    public let unrealizedPnl: Double
    public let unrealizedPnlPercent: Double
    public let weightPercent: Double

    public init(
        sector: String,
        marketValue: Double,
        costBasis: Double,
        unrealizedPnl: Double,
        unrealizedPnlPercent: Double,
        weightPercent: Double
    ) {
        self.sector = sector
        self.marketValue = marketValue
        self.costBasis = costBasis
        self.unrealizedPnl = unrealizedPnl
        self.unrealizedPnlPercent = unrealizedPnlPercent
        self.weightPercent = weightPercent
    }
}

public struct SectorGainsResponse: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let totalMarketValue: Double
    public let totalCostBasis: Double
    public let totalUnrealizedPnl: Double
    public let sectors: [SectorGainItem]

    public init(
        baseCurrency: String,
        totalMarketValue: Double,
        totalCostBasis: Double,
        totalUnrealizedPnl: Double,
        sectors: [SectorGainItem]
    ) {
        self.baseCurrency = baseCurrency
        self.totalMarketValue = totalMarketValue
        self.totalCostBasis = totalCostBasis
        self.totalUnrealizedPnl = totalUnrealizedPnl
        self.sectors = sectors
    }
}

public struct TransactionResponse: Codable, Sendable, Equatable {
    public let id: String
    public let accountId: String
    public let instrumentId: String
    public let type: String
    public let quantity: Double?
    public let price: Double?
    public let currency: String
    public let tradeDate: String
    public let settleDate: String?
    public let fees: Double?

    public init(
        id: String,
        accountId: String,
        instrumentId: String,
        type: String,
        quantity: Double?,
        price: Double?,
        currency: String,
        tradeDate: String,
        settleDate: String?,
        fees: Double?
    ) {
        self.id = id
        self.accountId = accountId
        self.instrumentId = instrumentId
        self.type = type
        self.quantity = quantity
        self.price = price
        self.currency = currency
        self.tradeDate = tradeDate
        self.settleDate = settleDate
        self.fees = fees
    }
}

public struct LotResponse: Codable, Sendable, Equatable {
    public let id: String
    public let accountId: String
    public let instrumentId: String
    public let openDate: String
    public let closeDate: String?
    public let openQuantity: Double
    public let remainingQuantity: Double
    public let openPrice: Double
    public let currency: String
    public let realizedPnl: Double?
    public let status: String

    public init(
        id: String,
        accountId: String,
        instrumentId: String,
        openDate: String,
        closeDate: String?,
        openQuantity: Double,
        remainingQuantity: Double,
        openPrice: Double,
        currency: String,
        realizedPnl: Double?,
        status: String
    ) {
        self.id = id
        self.accountId = accountId
        self.instrumentId = instrumentId
        self.openDate = openDate
        self.closeDate = closeDate
        self.openQuantity = openQuantity
        self.remainingQuantity = remainingQuantity
        self.openPrice = openPrice
        self.currency = currency
        self.realizedPnl = realizedPnl
        self.status = status
    }
}

public struct PnlBySymbol: Codable, Sendable, Equatable {
    public let symbol: String
    public let currency: String
    public let realizedPnl: Double
    public let unrealizedPnl: Double

    public init(symbol: String, currency: String, realizedPnl: Double, unrealizedPnl: Double) {
        self.symbol = symbol
        self.currency = currency
        self.realizedPnl = realizedPnl
        self.unrealizedPnl = unrealizedPnl
    }
}

public struct PnlResponse: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let items: [PnlBySymbol]

    public init(baseCurrency: String, items: [PnlBySymbol]) {
        self.baseCurrency = baseCurrency
        self.items = items
    }
}

public struct DividendProjectedItem: Codable, Sendable, Equatable {
    public let symbol: String
    public let exDividendDate: String
    public let paymentDate: String
    public let amountPerShare: Double
    public let projectedTotal: Double

    public init(symbol: String, exDividendDate: String, paymentDate: String, amountPerShare: Double, projectedTotal: Double) {
        self.symbol = symbol
        self.exDividendDate = exDividendDate
        self.paymentDate = paymentDate
        self.amountPerShare = amountPerShare
        self.projectedTotal = projectedTotal
    }
}

public struct DividendMonthlyBreakdown: Codable, Sendable, Equatable {
    public let month: String
    public let amount: Double

    public init(month: String, amount: Double) {
        self.month = month
        self.amount = amount
    }
}

public struct PortfolioDividendsResponse: Codable, Sendable, Equatable {
    public let annualProjectedIncome: Double
    public let upcomingDividends: [DividendProjectedItem]
    public let monthlyBreakdown: [DividendMonthlyBreakdown]

    public init(annualProjectedIncome: Double, upcomingDividends: [DividendProjectedItem], monthlyBreakdown: [DividendMonthlyBreakdown]) {
        self.annualProjectedIncome = annualProjectedIncome
        self.upcomingDividends = upcomingDividends
        self.monthlyBreakdown = monthlyBreakdown
    }
}
