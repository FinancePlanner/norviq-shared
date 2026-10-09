import Foundation
import Testing
@testable import StockPlanShared

struct MarketBriefDTOsTests {
    @Test
    func `slot and enum raw values match the wire format`() {
        #expect(MarketBriefSlot.allCases.map(\.rawValue) == ["morning", "evening"])
        #expect(MarketBriefDirection.down.rawValue == "down")
        #expect(MarketBriefItemKind.earnings.rawValue == "earnings")
    }

    @Test
    func `response round-trips through JSON with camelCase keys`() throws {
        let response = MarketBriefResponse(
            enabled: true,
            tradingDate: "2026-10-08",
            slot: .morning,
            language: "pt-PT",
            greeting: "Bom dia,",
            groups: [
                MarketBriefQuoteGroup(
                    id: "eu_open",
                    title: "Abertura europeia negativa",
                    tone: .down,
                    rows: [MarketBriefQuoteRow(
                        symbol: "^GDAXI",
                        flag: "🇩🇪",
                        name: "DAX",
                        level: "25.032",
                        changePercent: "0,77%",
                        direction: .down
                    )]
                ),
            ],
            items: [MarketBriefItem(kind: .highlight, text: "O tom é risk-off.", tickers: [], sourceUrl: nil)],
            generatedAt: "2026-10-08T07:15:00Z",
            degraded: false
        )
        let data = try JSONEncoder().encode(response)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"tradingDate\""))
        #expect(json.contains("\"changePercent\""))
        #expect(try JSONDecoder().decode(MarketBriefResponse.self, from: data) == response)
    }

    @Test
    func `empty response carries no brief`() {
        let empty = MarketBriefResponse.empty(language: "en", enabled: false)
        #expect(empty.enabled == false)
        #expect(empty.tradingDate == nil)
        #expect(empty.slot == nil)
        #expect(empty.groups.isEmpty)
        #expect(empty.items.isEmpty)
        #expect(empty.degraded == false)
    }
}
