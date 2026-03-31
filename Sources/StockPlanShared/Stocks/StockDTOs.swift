import Foundation

public struct StockRequest: Codable, Sendable, Equatable {
    public let symbol: String
    public let shares: Double
    public let buyPrice: Double
    public let buyDate: String
    public let notes: String?

    public init(symbol: String, shares: Double, buyPrice: Double, buyDate: String, notes: String?) {
        self.symbol = symbol
        self.shares = shares
        self.buyPrice = buyPrice
        self.buyDate = buyDate
        self.notes = notes
    }
}

public struct StockResponse: Codable, Sendable, Equatable {
    public let id: String
    public let symbol: String
    public let shares: Double
    public let buyPrice: Double
    public let buyDate: String
    public let notes: String?

    public init(
        id: String, symbol: String, shares: Double, buyPrice: Double, buyDate: String,
        notes: String?
    ) {
        self.id = id
        self.symbol = symbol
        self.shares = shares
        self.buyPrice = buyPrice
        self.buyDate = buyDate
        self.notes = notes
    }
}

public enum WatchlistStatus: String, Codable, Sendable, CaseIterable {
    case active
    case researching
    case waiting
    case ready
    case archived
}

public struct WatchlistItemRequest: Codable, Sendable, Equatable {
    public let symbol: String
    public let note: String?
    public let status: WatchlistStatus?
    public let nextReviewAt: String?

    public init(
        symbol: String,
        note: String? = nil,
        status: WatchlistStatus? = nil,
        nextReviewAt: String? = nil
    ) {
        self.symbol = symbol
        self.note = note
        self.status = status
        self.nextReviewAt = nextReviewAt
    }
}

public struct WatchlistItemUpdateRequest: Codable, Sendable, Equatable {
    public let note: String?
    public let status: WatchlistStatus?
    public let lastReviewedAt: String?
    public let nextReviewAt: String?

    public init(
        note: String? = nil,
        status: WatchlistStatus? = nil,
        lastReviewedAt: String? = nil,
        nextReviewAt: String? = nil
    ) {
        self.note = note
        self.status = status
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
    }
}

public struct WatchlistItemResponse: Codable, Sendable, Equatable {
    public let id: String
    public let symbol: String
    public let note: String?
    public let status: WatchlistStatus
    public let createdAt: String?
    public let updatedAt: String?
    public let lastReviewedAt: String?
    public let nextReviewAt: String?

    public init(
        id: String,
        symbol: String,
        note: String?,
        status: WatchlistStatus,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        lastReviewedAt: String? = nil,
        nextReviewAt: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.note = note
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
    }
}

public struct ResearchNoteRequest: Codable, Sendable, Equatable {
    public let symbol: String
    public let title: String?
    public let thesis: String
    public let risks: String?
    public let catalysts: String?
    public let referenceLinks: [String]?

    public init(
        symbol: String,
        title: String?,
        thesis: String,
        risks: String?,
        catalysts: String?,
        referenceLinks: [String]?
    ) {
        self.symbol = symbol
        self.title = title
        self.thesis = thesis
        self.risks = risks
        self.catalysts = catalysts
        self.referenceLinks = referenceLinks
    }
}

public struct ResearchNoteResponse: Codable, Sendable, Equatable {
    public let id: String
    public let symbol: String
    public let title: String?
    public let thesis: String
    public let risks: String?
    public let catalysts: String?
    public let referenceLinks: [String]?

    public init(
        id: String,
        symbol: String,
        title: String?,
        thesis: String,
        risks: String?,
        catalysts: String?,
        referenceLinks: [String]?
    ) {
        self.id = id
        self.symbol = symbol
        self.title = title
        self.thesis = thesis
        self.risks = risks
        self.catalysts = catalysts
        self.referenceLinks = referenceLinks
    }
}

// public enum ValuationScenario: String, Codable, Sendable {
//     case bear
//     case base
//     case bull
// }

// public struct ScenarioTargetRequest: Codable, Sendable, Equatable {
//     public let symbol: String
//     public let scenario: ValuationScenario
//     public let lowPrice: Double
//     public let highPrice: Double
//     public let targetPrice: Double
//     public let targetDate: String?
//     public let rationale: String?

//     public init(
//         symbol: String,
//         scenario: ValuationScenario,
//         lowPrice: Double,
//         highPrice: Double,
//         targetPrice: Double,
//         targetDate: String?,
//         rationale: String?
//     ) {
//         self.symbol = symbol
//         self.scenario = scenario
//         self.lowPrice = lowPrice
//         self.highPrice = highPrice
//         self.targetPrice = targetPrice
//         self.targetDate = targetDate
//         self.rationale = rationale
//     }
// }

public struct PriceRange: Codable, Sendable, Equatable {
    public let low: Double
    public let high: Double

    public init(low: Double, high: Double) {
        self.low = low
        self.high = high
    }
}

public struct StockValuationRequest: Codable, Sendable, Equatable {
    public let symbol: String
    public let bearCase: PriceRange
    public let baseCase: PriceRange
    public let bullCase: PriceRange
    public let rationale: String?
    public let targetDate: String?

    public init(
        symbol: String,
        bearCase: PriceRange,
        baseCase: PriceRange,
        bullCase: PriceRange,
        rationale: String?,
        targetDate: String?
    ) {
        self.symbol = symbol
        self.bearCase = bearCase
        self.baseCase = baseCase
        self.bullCase = bullCase
        self.rationale = rationale
        self.targetDate = targetDate
    }
}

public struct ScenarioTargetResponse: Codable, Sendable, Equatable {
    public let id: String
    public let symbol: String
    public let scenario: String
    public let targetPrice: Double
    public let targetDate: String?
    public let rationale: String?

    public init(
        id: String,
        symbol: String,
        scenario: String,
        targetPrice: Double,
        targetDate: String?,
        rationale: String?
    ) {
        self.id = id
        self.symbol = symbol
        self.scenario = scenario
        self.targetPrice = targetPrice
        self.targetDate = targetDate
        self.rationale = rationale
    }
}

public typealias TargetResponse = ScenarioTargetResponse

public struct TargetRequest: Codable, Sendable, Equatable {
    public let symbol: String
    public let scenario: String
    public let targetPrice: Double
    public let targetDate: String?
    public let rationale: String?

    public init(
        symbol: String,
        scenario: String,
        targetPrice: Double,
        targetDate: String? = nil,
        rationale: String? = nil
    ) {
        self.symbol = symbol
        self.scenario = scenario
        self.targetPrice = targetPrice
        self.targetDate = targetDate
        self.rationale = rationale
    }
}

public struct StockHistory: Codable, Sendable, Equatable {
    public let date: String
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Int

    public init(date: String, open: Double, high: Double, low: Double, close: Double, volume: Int) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

public struct StockNews: Codable, Sendable, Equatable {
    public let title: String
    public let url: String
    public let date: String

    public init(title: String, url: String, date: String) {
        self.title = title
        self.url = url
        self.date = date
    }
}

// MARK: - Bulk Import
public struct BulkStockRequest: Codable, Sendable, Equatable {
    public let stocks: [StockRequest]

    public init(stocks: [StockRequest]) {
        self.stocks = stocks
    }
}

public struct BulkStockResultItem: Codable, Sendable, Equatable {
    public let index: Int
    public let stock: StockResponse?
    public let error: String?

    public init(index: Int, stock: StockResponse? = nil, error: String? = nil) {
        self.index = index
        self.stock = stock
        self.error = error
    }
}

public struct BulkStockResponse: Codable, Sendable, Equatable {
    public let created: Int
    public let failed: Int
    public let results: [BulkStockResultItem]

    public init(created: Int, failed: Int, results: [BulkStockResultItem]) {
        self.created = created
        self.failed = failed
        self.results = results
    }
}

public struct StockValuationDraft: Codable, Sendable, Equatable {
    public let bearLow: Double
    public let bearHigh: Double
    public let baseLow: Double
    public let baseHigh: Double
    public let bullLow: Double
    public let bullHigh: Double
    public let rationale: String?
    public let targetDate: String?

    public init(
        bearLow: Double,
        bearHigh: Double,
        baseLow: Double,
        baseHigh: Double,
        bullLow: Double,
        bullHigh: Double,
        rationale: String? = nil,
        targetDate: String? = nil
    ) {
        self.bearLow = bearLow
        self.bearHigh = bearHigh
        self.baseLow = baseLow
        self.baseHigh = baseHigh
        self.bullLow = bullLow
        self.bullHigh = bullHigh
        self.rationale = rationale
        self.targetDate = targetDate
    }
}

