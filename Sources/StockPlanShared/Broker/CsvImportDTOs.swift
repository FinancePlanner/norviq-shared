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
