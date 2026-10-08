import Foundation

/// Which of the two daily briefs. Morning runs 15 minutes after the European
/// open (08:15 Lisbon); evening runs after the US close (22:30 Lisbon).
public enum MarketBriefSlot: String, Codable, Sendable, CaseIterable, Hashable {
    case morning
    case evening
}

/// Sign of a move. Clients draw 🟢 / 🔴 / ⚪️ from it; the formatted numbers
/// stay unsigned.
public enum MarketBriefDirection: String, Codable, Sendable {
    case up
    case down
    case flat
}

public enum MarketBriefItemKind: String, Codable, Sendable {
    /// Morning 📌 line.
    case highlight
    /// Morning 📍 line: a company reporting today.
    case earnings
    /// Evening numbered story.
    case story
}

/// One index line, e.g. 🇩🇪 DAX → 25.032 → 🔴 0,77%.
public struct MarketBriefQuoteRow: Codable, Sendable, Equatable {
    public let symbol: String
    public let flag: String
    public let name: String
    /// Already formatted for `MarketBriefResponse.language`, e.g. "25.032".
    public let level: String
    /// Unsigned and formatted, e.g. "0,77%". `direction` carries the sign.
    public let changePercent: String
    public let direction: MarketBriefDirection

    public init(
        symbol: String,
        flag: String,
        name: String,
        level: String,
        changePercent: String,
        direction: MarketBriefDirection
    ) {
        self.symbol = symbol
        self.flag = flag
        self.name = name
        self.level = level
        self.changePercent = changePercent
        self.direction = direction
    }
}

/// A headed block of rows, e.g. "Futuros americanos negativos".
public struct MarketBriefQuoteGroup: Codable, Sendable, Equatable {
    /// `eu_open`, `us_futures`, `eu_close` or `us_close`.
    public let id: String
    public let title: String
    /// Worked out on the server from the rows; never written by the model.
    public let tone: MarketBriefDirection
    public let rows: [MarketBriefQuoteRow]

    public init(id: String, title: String, tone: MarketBriefDirection, rows: [MarketBriefQuoteRow]) {
        self.id = id
        self.title = title
        self.tone = tone
        self.rows = rows
    }
}

/// One line of text. Summarised, never copied from a publisher.
public struct MarketBriefItem: Codable, Sendable, Equatable {
    public let kind: MarketBriefItemKind
    public let text: String
    /// Without the "$", e.g. ["NVDA"].
    public let tickers: [String]
    /// The https source the line came from, when it used web search.
    public let sourceUrl: String?

    public init(kind: MarketBriefItemKind, text: String, tickers: [String], sourceUrl: String?) {
        self.kind = kind
        self.text = text
        self.tickers = tickers
        self.sourceUrl = sourceUrl
    }
}

/// `GET /v1/market/brief`. The same for every user; only the language varies.
public struct MarketBriefResponse: Codable, Sendable, Equatable {
    public let enabled: Bool
    /// Lisbon calendar date, `yyyy-MM-dd`. Nil when no brief exists yet.
    public let tradingDate: String?
    public let slot: MarketBriefSlot?
    /// `en` or `pt-PT`.
    public let language: String
    public let greeting: String?
    /// Empty when no market data was fresh (holiday, provider down).
    public let groups: [MarketBriefQuoteGroup]
    public let items: [MarketBriefItem]
    /// ISO 8601. Nil when no brief exists yet.
    public let generatedAt: String?
    /// True when web search was unavailable and the text came from in-house
    /// sources only.
    public let degraded: Bool

    public init(
        enabled: Bool,
        tradingDate: String?,
        slot: MarketBriefSlot?,
        language: String,
        greeting: String?,
        groups: [MarketBriefQuoteGroup],
        items: [MarketBriefItem],
        generatedAt: String?,
        degraded: Bool
    ) {
        self.enabled = enabled
        self.tradingDate = tradingDate
        self.slot = slot
        self.language = language
        self.greeting = greeting
        self.groups = groups
        self.items = items
        self.generatedAt = generatedAt
        self.degraded = degraded
    }

    /// Feature off (`enabled: false`) or on with nothing generated yet.
    public static func empty(language: String, enabled: Bool) -> MarketBriefResponse {
        MarketBriefResponse(
            enabled: enabled,
            tradingDate: nil,
            slot: nil,
            language: language,
            greeting: nil,
            groups: [],
            items: [],
            generatedAt: nil,
            degraded: false
        )
    }
}
