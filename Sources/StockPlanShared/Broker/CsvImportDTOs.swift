import Foundation

public struct CsvImportPreviewItem: Codable, Sendable, Equatable {
    public let line: Int
    public let symbol: String
    public let shares: Double?
    public let buyPrice: Double?
    public let buyDate: String?
    public let notes: String?

    public init(line: Int, symbol: String, shares: Double? = nil, buyPrice: Double? = nil, buyDate: String? = nil, notes: String? = nil) {
        self.line = line
        self.symbol = symbol
        self.shares = shares
        self.buyPrice = buyPrice
        self.buyDate = buyDate
        self.notes = notes
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

    public init(provider: String, inserted: [StockResponse], updated: [StockResponse], errors: [CsvImportPreviewError]) {
        self.provider = provider
        self.inserted = inserted
        self.updated = updated
        self.errors = errors
    }
}
