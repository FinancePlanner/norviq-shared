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
    public let c: Double
    public let d: Double?
    public let dp: Double?
    public let h: Double?
    public let l: Double?
    public let o: Double?
    public let pc: Double?
    public let t: Int

    public init(
        symbol: String,
        currency: String,
        c: Double,
        d: Double? = nil,
        dp: Double? = nil,
        h: Double? = nil,
        l: Double? = nil,
        o: Double? = nil,
        pc: Double? = nil,
        t: Int
    ) {
        self.symbol = symbol
        self.currency = currency
        self.c = c
        self.d = d
        self.dp = dp
        self.h = h
        self.l = l
        self.o = o
        self.pc = pc
        self.t = t
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
