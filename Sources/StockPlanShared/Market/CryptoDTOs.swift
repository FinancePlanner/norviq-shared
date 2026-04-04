import Foundation

public struct CryptoAssetResponse: Codable, Sendable, Equatable, Identifiable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let exchange: String?
    public let icoDate: String?
    public let circulatingSupply: Double?
    public let totalSupply: Double?

    public init(
        symbol: String,
        name: String,
        exchange: String? = nil,
        icoDate: String? = nil,
        circulatingSupply: Double? = nil,
        totalSupply: Double? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.exchange = exchange
        self.icoDate = icoDate
        self.circulatingSupply = circulatingSupply
        self.totalSupply = totalSupply
    }
}

public struct CryptoQuoteResponse: Codable, Sendable, Equatable, Identifiable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let price: Double
    public let changePercentage: Double
    public let change: Double
    public let volume: Double?
    public let dayLow: Double?
    public let dayHigh: Double?
    public let yearHigh: Double?
    public let yearLow: Double?
    public let marketCap: Double?
    public let priceAvg50: Double?
    public let priceAvg200: Double?
    public let exchange: String?
    public let open: Double?
    public let previousClose: Double?
    public let timestamp: Int

    public init(
        symbol: String,
        name: String,
        price: Double,
        changePercentage: Double,
        change: Double,
        volume: Double? = nil,
        dayLow: Double? = nil,
        dayHigh: Double? = nil,
        yearHigh: Double? = nil,
        yearLow: Double? = nil,
        marketCap: Double? = nil,
        priceAvg50: Double? = nil,
        priceAvg200: Double? = nil,
        exchange: String? = nil,
        open: Double? = nil,
        previousClose: Double? = nil,
        timestamp: Int
    ) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercentage = changePercentage
        self.change = change
        self.volume = volume
        self.dayLow = dayLow
        self.dayHigh = dayHigh
        self.yearHigh = yearHigh
        self.yearLow = yearLow
        self.marketCap = marketCap
        self.priceAvg50 = priceAvg50
        self.priceAvg200 = priceAvg200
        self.exchange = exchange
        self.open = open
        self.previousClose = previousClose
        self.timestamp = timestamp
    }
}

public struct CryptoHistoricalPoint: Codable, Sendable, Equatable, Identifiable {
    public var id: String { date }
    public let date: String
    public let open: Double?
    public let low: Double?
    public let high: Double?
    public let close: Double
    public let volume: Double?

    public init(
        date: String,
        open: Double? = nil,
        low: Double? = nil,
        high: Double? = nil,
        close: Double,
        volume: Double? = nil
    ) {
        self.date = date
        self.open = open
        self.low = low
        self.high = high
        self.close = close
        self.volume = volume
    }
}
