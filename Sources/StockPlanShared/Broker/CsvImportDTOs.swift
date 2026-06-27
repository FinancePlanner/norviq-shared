import Foundation

public enum CsvImportExistingPositionKind: String, Codable, Sendable, Equatable {
    case none
    case manual
    case imported
    case mixed
}

public struct CsvImportPreviewItem: Codable, Sendable, Equatable {
    public let line: Int
    public let symbol: String
    public let shares: Double?
    public let buyPrice: Double?
    public let buyDate: String?
    public let notes: String?
    public let existingPositionKind: CsvImportExistingPositionKind
    public let willReplaceExistingImport: Bool

    public init(
        line: Int,
        symbol: String,
        shares: Double? = nil,
        buyPrice: Double? = nil,
        buyDate: String? = nil,
        notes: String? = nil,
        existingPositionKind: CsvImportExistingPositionKind = .none,
        willReplaceExistingImport: Bool = false
    ) {
        self.line = line
        self.symbol = symbol
        self.shares = shares
        self.buyPrice = buyPrice
        self.buyDate = buyDate
        self.notes = notes
        self.existingPositionKind = existingPositionKind
        self.willReplaceExistingImport = willReplaceExistingImport
    }
}

public struct CsvImportPreviewError: Codable, Sendable, Equatable {
    public let line: Int
    public let message: String

    public init(line: Int, message: String) {
        self.line = line
        self.message = message
    }
}

public struct CsvImportPreviewResponse: Codable, Sendable, Equatable {
    public let provider: String
    public let items: [CsvImportPreviewItem]
    public let errors: [CsvImportPreviewError]

    public init(provider: String, items: [CsvImportPreviewItem], errors: [CsvImportPreviewError]) {
        self.provider = provider
        self.items = items
        self.errors = errors
    }
}

public struct CsvImportCommitResponse: Codable, Sendable, Equatable {
    public let provider: String
    public let inserted: [StockResponse]
    public let updated: [StockResponse]
    public let errors: [CsvImportPreviewError]
    public let replacedSymbols: [String]
    public let importedLotsCount: Int

    public init(
        provider: String,
        inserted: [StockResponse],
        updated: [StockResponse],
        errors: [CsvImportPreviewError],
        replacedSymbols: [String] = [],
        importedLotsCount: Int = 0
    ) {
        self.provider = provider
        self.inserted = inserted
        self.updated = updated
        self.errors = errors
        self.replacedSymbols = replacedSymbols
        self.importedLotsCount = importedLotsCount
    }
}

public struct WatchlistCsvImportPreviewItem: Codable, Sendable, Equatable {
    public let line: Int
    public let symbol: String
    public let note: String?
    public let status: WatchlistStatus?
    public let existingItemId: String?
    public let willUpdateExisting: Bool

    public init(
        line: Int,
        symbol: String,
        note: String? = nil,
        status: WatchlistStatus? = nil,
        existingItemId: String? = nil,
        willUpdateExisting: Bool = false
    ) {
        self.line = line
        self.symbol = symbol
        self.note = note
        self.status = status
        self.existingItemId = existingItemId
        self.willUpdateExisting = willUpdateExisting
    }
}

public struct WatchlistCsvImportPreviewResponse: Codable, Sendable, Equatable {
    public let watchlistListId: String
    public let items: [WatchlistCsvImportPreviewItem]
    public let errors: [CsvImportPreviewError]

    public init(
        watchlistListId: String,
        items: [WatchlistCsvImportPreviewItem],
        errors: [CsvImportPreviewError]
    ) {
        self.watchlistListId = watchlistListId
        self.items = items
        self.errors = errors
    }
}

public struct WatchlistCsvImportCommitResponse: Codable, Sendable, Equatable {
    public let watchlistListId: String
    public let inserted: [WatchlistItemResponse]
    public let updated: [WatchlistItemResponse]
    public let errors: [CsvImportPreviewError]

    public init(
        watchlistListId: String,
        inserted: [WatchlistItemResponse],
        updated: [WatchlistItemResponse],
        errors: [CsvImportPreviewError]
    ) {
        self.watchlistListId = watchlistListId
        self.inserted = inserted
        self.updated = updated
        self.errors = errors
    }
}
