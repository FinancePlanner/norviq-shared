import Foundation

public struct StockDetailsResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let company: String
    public let latestPrice: Double
    public let changePercent: Double

    public init(symbol: String, company: String, latestPrice: Double, changePercent: Double) {
        self.symbol = symbol
        self.company = company
        self.latestPrice = latestPrice
        self.changePercent = changePercent
    }
}

public struct QuoteResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let currency: String
    public let currentPrice: Double
    public let change: Double?
    public let percentChange: Double?
    public let high: Double?
    public let low: Double?
    public let open: Double?
    public let previousClose: Double?
    public let timestamp: Double

    enum CodingKeys: String, CodingKey {
        case symbol, currency
        case currentPrice = "c"
        case change = "d"
        case percentChange = "dp"
        case high = "h"
        case low = "l"
        case open = "o"
        case previousClose = "pc"
        case timestamp = "t"
    }

    public init(
        symbol: String,
        currency: String,
        currentPrice: Double,
        change: Double? = nil,
        percentChange: Double? = nil,
        high: Double? = nil,
        low: Double? = nil,
        open: Double? = nil,
        previousClose: Double? = nil,
        timestamp: Double
    ) {

        self.symbol = symbol
        self.currency = currency
        self.currentPrice = currentPrice
        self.change = change
        self.percentChange = percentChange
        self.high = high
        self.low = low
        self.open = open
        self.previousClose = previousClose
        self.timestamp = timestamp
    }

    public var isPositiveSession: Bool {
        (change ?? 0) >= 0
    }

    public var rangeProgress: Double {
        guard let high, let low, high > low else { return 0.5 }
        let progress = (currentPrice - low) / (high - low)
        return min(max(progress, 0), 1)
    }
}

public struct CompanyProfileResponse: Codable, Sendable, Equatable {
    public let country: String?
    public let currency: String?
    public let estimateCurrency: String?
    public let exchange: String?
    public let finnhubIndustry: String?
    public let ipo: String?
    public let logo: String?
    public let marketCapitalization: Double?
    public let name: String?
    public let phone: String?
    public let shareOutstanding: Double?
    public let ticker: String?
    public let weburl: String?

    public init(
        country: String?,
        currency: String?,
        estimateCurrency: String?,
        exchange: String?,
        finnhubIndustry: String?,
        ipo: String?,
        logo: String?,
        marketCapitalization: Double?,
        name: String?,
        phone: String?,
        shareOutstanding: Double?,
        ticker: String?,
        weburl: String?
    ) {
        self.country = country
        self.currency = currency
        self.estimateCurrency = estimateCurrency
        self.exchange = exchange
        self.finnhubIndustry = finnhubIndustry
        self.ipo = ipo
        self.logo = logo
        self.marketCapitalization = marketCapitalization
        self.name = name
        self.phone = phone
        self.shareOutstanding = shareOutstanding
        self.ticker = ticker
        self.weburl = weburl
    }
}

public struct PriceBarResponse: Codable, Sendable, Equatable {
    public let date: String
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Int?

    public init(date: String, open: Double, high: Double, low: Double, close: Double, volume: Int?)
    {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

public struct HistoryResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let currency: String
    public let bars: [PriceBarResponse]

    public init(symbol: String, currency: String, bars: [PriceBarResponse]) {
        self.symbol = symbol
        self.currency = currency
        self.bars = bars
    }
}

public struct SearchResultResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let name: String
    public let exchange: String
    public let currency: String
    public let conid: String

    public init(symbol: String, name: String, exchange: String, currency: String, conid: String) {
        self.symbol = symbol
        self.name = name
        self.exchange = exchange
        self.currency = currency
        self.conid = conid
    }
}

public struct FxRateResponse: Codable, Sendable, Equatable {
    public let base: String
    public let quote: String
    public let rate: Double
    public let date: String

    public init(base: String, quote: String, rate: Double, date: String) {
        self.base = base
        self.quote = quote
        self.rate = rate
        self.date = date
    }
}

public struct QuoteBatchResponse: Codable, Sendable, Equatable {
    public let quotes: [QuoteResponse]

    public init(quotes: [QuoteResponse]) {
        self.quotes = quotes
    }
}

public enum BasicFinancialMetricValue: Codable, Sendable, Equatable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case null

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .number(value)
            return
        }

        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported basic financial metric value."
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public struct BasicFinancialSeriesPoint: Codable, Sendable, Equatable {
    public let period: String
    public let value: Double

    enum CodingKeys: String, CodingKey {
        case period
        case value = "v"
    }

    public init(period: String, value: Double) {
        self.period = period
        self.value = value
    }
}

public struct BasicFinancialsResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let metricType: String
    public let metric: [String: BasicFinancialMetricValue]
    public let series: [String: [String: [BasicFinancialSeriesPoint]]]

    public init(
        symbol: String,
        metricType: String,
        metric: [String: BasicFinancialMetricValue],
        series: [String: [String: [BasicFinancialSeriesPoint]]]
    ) {
        self.symbol = symbol
        self.metricType = metricType
        self.metric = metric
        self.series = series
    }
}

public struct RatiosTTMResponse: Content, Sendable, Equatable {
    let symbol: String
    let grossProfitMarginTTM: Double?
    let ebitMarginTTM: Double?
    let ebitdaMarginTTM: Double?
    let operatingProfitMarginTTM: Double?
    let pretaxProfitMarginTTM: Double?
    let continuousOperationsProfitMarginTTM: Double?
    let netProfitMarginTTM: Double?
    let bottomLineProfitMarginTTM: Double?
    let receivablesTurnoverTTM: Double?
    let payablesTurnoverTTM: Double?
    let inventoryTurnoverTTM: Double?
    let fixedAssetTurnoverTTM: Double?
    let assetTurnoverTTM: Double?
    let currentRatioTTM: Double?
    let quickRatioTTM: Double?
    let solvencyRatioTTM: Double?
    let cashRatioTTM: Double?
    let priceToEarningsRatioTTM: Double?
    let priceToEarningsGrowthRatioTTM: Double?
    let forwardPriceToEarningsGrowthRatioTTM: Double?
    let priceToBookRatioTTM: Double?
    let priceToSalesRatioTTM: Double?
    let priceToFreeCashFlowRatioTTM: Double?
    let priceToOperatingCashFlowRatioTTM: Double?
    let debtToAssetsRatioTTM: Double?
    let debtToEquityRatioTTM: Double?
    let debtToCapitalRatioTTM: Double?
    let longTermDebtToCapitalRatioTTM: Double?
    let financialLeverageRatioTTM: Double?
    let workingCapitalTurnoverRatioTTM: Double?
    let operatingCashFlowRatioTTM: Double?
    let operatingCashFlowSalesRatioTTM: Double?
    let freeCashFlowOperatingCashFlowRatioTTM: Double?
    let debtServiceCoverageRatioTTM: Double?
    let interestCoverageRatioTTM: Double?
    let shortTermOperatingCashFlowCoverageRatioTTM: Double?
    let operatingCashFlowCoverageRatioTTM: Double?
    let capitalExpenditureCoverageRatioTTM: Double?
    let dividendPaidAndCapexCoverageRatioTTM: Double?
    let dividendPayoutRatioTTM: Double?
    let dividendYieldTTM: Double?
    let enterpriseValueTTM: Double?
    let revenuePerShareTTM: Double?
    let netIncomePerShareTTM: Double?
    let interestDebtPerShareTTM: Double?
    let cashPerShareTTM: Double?
    let bookValuePerShareTTM: Double?
    let tangibleBookValuePerShareTTM: Double?
    let shareholdersEquityPerShareTTM: Double?
    let operatingCashFlowPerShareTTM: Double?
    let capexPerShareTTM: Double?
    let freeCashFlowPerShareTTM: Double?
    let netIncomePerEBTTTM: Double?
    let ebtPerEbitTTM: Double?
    let priceToFairValueTTM: Double?
    let debtToMarketCapTTM: Double?
    let effectiveTaxRateTTM: Double?
    let enterpriseValueMultipleTTM: Double?
}

public struct BalanceSheetStatementResponse: Content, Sendable, Equatable {
    let date: String
    let symbol: String
    let reportedCurrency: String?
    let cik: String?
    let filingDate: String?
    let acceptedDate: String?
    let fiscalYear: String?
    let period: String?
    let cashAndCashEquivalents: Double?
    let shortTermInvestments: Double?
    let cashAndShortTermInvestments: Double?
    let netReceivables: Double?
    let accountsReceivables: Double?
    let otherReceivables: Double?
    let inventory: Double?
    let prepaids: Double?
    let otherCurrentAssets: Double?
    let totalCurrentAssets: Double?
    let propertyPlantEquipmentNet: Double?
    let goodwill: Double?
    let intangibleAssets: Double?
    let goodwillAndIntangibleAssets: Double?
    let longTermInvestments: Double?
    let taxAssets: Double?
    let otherNonCurrentAssets: Double?
    let totalNonCurrentAssets: Double?
    let otherAssets: Double?
    let totalAssets: Double?
    let totalPayables: Double?
    let accountPayables: Double?
    let otherPayables: Double?
    let accruedExpenses: Double?
    let shortTermDebt: Double?
    let capitalLeaseObligationsCurrent: Double?
    let taxPayables: Double?
    let deferredRevenue: Double?
    let otherCurrentLiabilities: Double?
    let totalCurrentLiabilities: Double?
    let longTermDebt: Double?
    let deferredRevenueNonCurrent: Double?
    let deferredTaxLiabilitiesNonCurrent: Double?
    let otherNonCurrentLiabilities: Double?
    let totalNonCurrentLiabilities: Double?
    let otherLiabilities: Double?
    let capitalLeaseObligations: Double?
    let totalLiabilities: Double?
    let treasuryStock: Double?
    let preferredStock: Double?
    let commonStock: Double?
    let retainedEarnings: Double?
    let additionalPaidInCapital: Double?
    let accumulatedOtherComprehensiveIncomeLoss: Double?
    let otherTotalStockholdersEquity: Double?
    let totalStockholdersEquity: Double?
    let totalEquity: Double?
    let minorityInterest: Double?
    let totalLiabilitiesAndTotalEquity: Double?
    let totalInvestments: Double?
    let totalDebt: Double?
    let netDebt: Double?
}

public struct CashFlowStatementResponse: Content, Sendable, Equatable {
    let date: String
    let symbol: String
    let reportedCurrency: String?
    let cik: String?
    let filingDate: String?
    let acceptedDate: String?
    let fiscalYear: String?
    let period: String?
    let netIncome: Double?
    let depreciationAndAmortization: Double?
    let deferredIncomeTax: Double?
    let stockBasedCompensation: Double?
    let changeInWorkingCapital: Double?
    let accountsReceivables: Double?
    let inventory: Double?
    let accountsPayables: Double?
    let otherWorkingCapital: Double?
    let otherNonCashItems: Double?
    let netCashProvidedByOperatingActivities: Double?
    let investmentsInPropertyPlantAndEquipment: Double?
    let acquisitionsNet: Double?
    let purchasesOfInvestments: Double?
    let salesMaturitiesOfInvestments: Double?
    let otherInvestingActivities: Double?
    let netCashProvidedByInvestingActivities: Double?
    let netDebtIssuance: Double?
    let longTermNetDebtIssuance: Double?
    let shortTermNetDebtIssuance: Double?
    let netStockIssuance: Double?
    let netCommonStockIssuance: Double?
    let commonStockIssuance: Double?
    let commonStockRepurchased: Double?
    let netPreferredStockIssuance: Double?
    let netDividendsPaid: Double?
    let commonDividendsPaid: Double?
    let preferredDividendsPaid: Double?
    let otherFinancingActivities: Double?
    let netCashProvidedByFinancingActivities: Double?
    let effectOfForexChangesOnCash: Double?
    let netChangeInCash: Double?
    let cashAtEndOfPeriod: Double?
    let cashAtBeginningOfPeriod: Double?
    let operatingCashFlow: Double?
    let capitalExpenditure: Double?
    let freeCashFlow: Double?
    let incomeTaxesPaid: Double?
    let interestPaid: Double?
}

public struct FinancialGrowthResponse: Content, Sendable, Equatable {
    let symbol: String
    let date: String
    let fiscalYear: String?
    let period: String?
    let reportedCurrency: String?
    let revenueGrowth: Double?
    let grossProfitGrowth: Double?
    let ebitgrowth: Double?
    let operatingIncomeGrowth: Double?
    let netIncomeGrowth: Double?
    let epsgrowth: Double?
    let epsdilutedGrowth: Double?
    let weightedAverageSharesGrowth: Double?
    let weightedAverageSharesDilutedGrowth: Double?
    let dividendsPerShareGrowth: Double?
    let operatingCashFlowGrowth: Double?
    let receivablesGrowth: Double?
    let inventoryGrowth: Double?
    let assetGrowth: Double?
    let bookValueperShareGrowth: Double?
    let debtGrowth: Double?
    let rdexpenseGrowth: Double?
    let sgaexpensesGrowth: Double?
    let freeCashFlowGrowth: Double?
    let tenYRevenueGrowthPerShare: Double?
    let fiveYRevenueGrowthPerShare: Double?
    let threeYRevenueGrowthPerShare: Double?
    let tenYOperatingCFGrowthPerShare: Double?
    let fiveYOperatingCFGrowthPerShare: Double?
    let threeYOperatingCFGrowthPerShare: Double?
    let tenYNetIncomeGrowthPerShare: Double?
    let fiveYNetIncomeGrowthPerShare: Double?
    let threeYNetIncomeGrowthPerShare: Double?
    let tenYShareholdersEquityGrowthPerShare: Double?
    let fiveYShareholdersEquityGrowthPerShare: Double?
    let threeYShareholdersEquityGrowthPerShare: Double?
    let tenYDividendperShareGrowthPerShare: Double?
    let fiveYDividendperShareGrowthPerShare: Double?
    let threeYDividendperShareGrowthPerShare: Double?
    let ebitdaGrowth: Double?
    let growthCapitalExpenditure: Double?
    let tenYBottomLineNetIncomeGrowthPerShare: Double?
    let fiveYBottomLineNetIncomeGrowthPerShare: Double?
    let threeYBottomLineNetIncomeGrowthPerShare: Double?
}

public struct AnalystEstimatesResponse: Content, Sendable, Equatable {
    let symbol: String
    let date: String
    let revenueLow: Double?
    let revenueHigh: Double?
    let revenueAvg: Double?
    let ebitdaLow: Double?
    let ebitdaHigh: Double?
    let ebitdaAvg: Double?
    let ebitLow: Double?
    let ebitHigh: Double?
    let ebitAvg: Double?
    let netIncomeLow: Double?
    let netIncomeHigh: Double?
    let netIncomeAvg: Double?
    let sgaExpenseLow: Double?
    let sgaExpenseHigh: Double?
    let sgaExpenseAvg: Double?
    let epsAvg: Double?
    let epsHigh: Double?
    let epsLow: Double?
    let numAnalystsRevenue: Int?
    let numAnalystsEps: Int?
}

public struct RatiosResponse: Content, Sendable, Equatable {
    let symbol: String
    let date: String
    let fiscalYear: String?
    let period: String?
    let reportedCurrency: String?
    let grossProfitMargin: Double?
    let ebitMargin: Double?
    let ebitdaMargin: Double?
    let operatingProfitMargin: Double?
    let pretaxProfitMargin: Double?
    let continuousOperationsProfitMargin: Double?
    let netProfitMargin: Double?
    let bottomLineProfitMargin: Double?
    let receivablesTurnover: Double?
    let payablesTurnover: Double?
    let inventoryTurnover: Double?
    let fixedAssetTurnover: Double?
    let assetTurnover: Double?
    let currentRatio: Double?
    let quickRatio: Double?
    let solvencyRatio: Double?
    let cashRatio: Double?
    let priceToEarningsRatio: Double?
    let priceToEarningsGrowthRatio: Double?
    let forwardPriceToEarningsGrowthRatio: Double?
    let priceToBookRatio: Double?
    let priceToSalesRatio: Double?
    let priceToFreeCashFlowRatio: Double?
    let priceToOperatingCashFlowRatio: Double?
    let debtToAssetsRatio: Double?
    let debtToEquityRatio: Double?
    let debtToCapitalRatio: Double?
    let longTermDebtToCapitalRatio: Double?
    let financialLeverageRatio: Double?
    let workingCapitalTurnoverRatio: Double?
    let operatingCashFlowRatio: Double?
    let operatingCashFlowSalesRatio: Double?
    let freeCashFlowOperatingCashFlowRatio: Double?
    let debtServiceCoverageRatio: Double?
    let interestCoverageRatio: Double?
    let shortTermOperatingCashFlowCoverageRatio: Double?
    let operatingCashFlowCoverageRatio: Double?
    let capitalExpenditureCoverageRatio: Double?
    let dividendPaidAndCapexCoverageRatio: Double?
    let dividendPayoutRatio: Double?
    let dividendYield: Double?
    let dividendYieldPercentage: Double?
    let revenuePerShare: Double?
    let netIncomePerShare: Double?
    let interestDebtPerShare: Double?
    let cashPerShare: Double?
    let bookValuePerShare: Double?
    let tangibleBookValuePerShare: Double?
    let shareholdersEquityPerShare: Double?
    let operatingCashFlowPerShare: Double?
    let capexPerShare: Double?
    let freeCashFlowPerShare: Double?
    let netIncomePerEBT: Double?
    let ebtPerEbit: Double?
    let priceToFairValue: Double?
    let debtToMarketCap: Double?
    let effectiveTaxRate: Double?
    let enterpriseValueMultiple: Double?
}
