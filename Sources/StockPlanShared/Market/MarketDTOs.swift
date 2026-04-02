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

    public init(date: String, open: Double, high: Double, low: Double, close: Double, volume: Int?) {
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
