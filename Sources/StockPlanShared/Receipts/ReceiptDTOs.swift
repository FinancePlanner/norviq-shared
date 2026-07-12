import Foundation

/// How a receipt draft was produced.
public enum ReceiptSource: String, Codable, Sendable, CaseIterable {
    /// Parsed from a structured fiscal QR code (e.g. Portuguese AT format).
    case qr
    /// Extracted from a photo via optical character recognition.
    case ocr
}

/// A single VAT bracket extracted from a fiscal receipt.
public struct ReceiptVATLine: Codable, Sendable, Equatable {
    /// VAT rate label as reported by the receipt (e.g. "reduced", "standard").
    public let rate: String
    /// Net taxable base for this bracket.
    public let base: Double?
    /// VAT amount for this bracket.
    public let amount: Double?

    public init(rate: String, base: Double? = nil, amount: Double? = nil) {
        self.rate = rate
        self.base = base
        self.amount = amount
    }
}

/// A pre-filled expense draft extracted from a scanned receipt. The client turns
/// this into an expense once the user assigns a budget pillar and category — the
/// draft intentionally carries no pillar/category so scanning never guesses those.
public struct ReceiptDraft: Codable, Sendable, Equatable {
    /// Merchant display name when known. Fiscal QR codes carry only a tax id, so
    /// this is often empty for QR-sourced drafts and filled from OCR text.
    public let merchant: String?
    /// Total amount paid, including tax.
    public let total: Double?
    /// ISO 4217 currency code (e.g. "EUR"). Nil when the source doesn't state it.
    public let currency: String?
    /// Purchase date as `YYYY-MM-DD`, matching `ExpenseRequest.occurredOn`.
    public let date: String?
    /// Merchant tax identifier (e.g. Portuguese NIF) when present in a fiscal QR.
    public let taxId: String?
    /// Total VAT/tax amount when reported.
    public let taxTotal: Double?
    /// Per-bracket VAT breakdown when reported.
    public let vatLines: [ReceiptVATLine]
    /// Extraction confidence in `0...1`. QR parses are 1.0; OCR is lower.
    public let confidence: Double
    /// Whether this draft came from a QR parse or OCR.
    public let source: ReceiptSource
    /// The raw fiscal QR payload, retained for QR-sourced drafts for auditing.
    public let rawPayload: String?

    public init(
        merchant: String? = nil,
        total: Double? = nil,
        currency: String? = nil,
        date: String? = nil,
        taxId: String? = nil,
        taxTotal: Double? = nil,
        vatLines: [ReceiptVATLine] = [],
        confidence: Double,
        source: ReceiptSource,
        rawPayload: String? = nil
    ) {
        self.merchant = merchant
        self.total = total
        self.currency = currency
        self.date = date
        self.taxId = taxId
        self.taxTotal = taxTotal
        self.vatLines = vatLines
        self.confidence = confidence
        self.source = source
        self.rawPayload = rawPayload
    }
}

/// Request body for `POST /v1/receipts/parse-qr`: the raw decoded QR string.
public struct ReceiptParseQRRequest: Codable, Sendable, Equatable {
    public let payload: String

    public init(payload: String) {
        self.payload = payload
    }
}

/// Response wrapping a parsed draft. `recognized` is false when no supported
/// fiscal QR format matched, so clients can fall back to OCR or manual entry.
public struct ReceiptDraftResponse: Codable, Sendable, Equatable {
    public let recognized: Bool
    public let draft: ReceiptDraft?

    public init(recognized: Bool, draft: ReceiptDraft?) {
        self.recognized = recognized
        self.draft = draft
    }
}
