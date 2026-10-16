import Foundation
import Testing
@testable import StockPlanShared

@Suite("Recap DTOs")
struct RecapDTOsTests {
    static let samples: [RecapSlide] = [
        .intro(RecapIntroSlide(periodLabel: "October 2026", activeDays: 12)),
        .streak(RecapStreakSlide(longestStreakDays: 7, activeDays: 12)),
        .topTickers(RecapTopTickersSlide(tickers: [RecapTickerStat(symbol: "AAPL", touches: 3)])),
        .trades(RecapTradesSlide(tradeCount: 5, buyCount: 3, sellCount: 2, mostTradedSymbol: "MSFT")),
        .research(RecapResearchSlide(notesWritten: 2, watchlistAdded: 4, targetsSet: 3, targetsHit: 1)),
        .growth(RecapGrowthSlide(growth: [RecapGrowth(currency: "USD", startValue: 100, endValue: 110)])),
        .dividends(RecapDividendsSlide(
            received: [RecapMoney(amount: 12.5, currency: "EUR")],
            paymentCount: 2,
            payerCount: 1
        )),
        .goals(RecapGoalsSlide(contributed: [RecapMoney(amount: 300, currency: "USD")], contributionCount: 3)),
        .badges(RecapBadgesSlide(badges: [RecapBadge(type: "streak", tier: "gold")], xpEarned: 250)),
        .personality(RecapPersonalitySlide(archetype: .saver)),
        .missedYou(RecapMissedYouSlide(bestStreakDays: 9, totalBadges: 4)),
        .outro(RecapOutroSlide(isFirstChapter: true, nextPeriodLabel: "November 2026")),
    ]

    @Test
    func `every slide case round trips`() throws {
        #expect(Self.samples.count == 12)
        let data = try JSONEncoder().encode(Self.samples)
        let decoded = try JSONDecoder().decode([RecapSlide].self, from: data)
        #expect(decoded == Self.samples)
    }

    @Test
    func `slide wire shape uses snake case type and sibling key`() throws {
        let slide = RecapSlide.topTickers(RecapTopTickersSlide(tickers: [RecapTickerStat(symbol: "AAPL", touches: 3)]))
        let data = try JSONEncoder().encode(slide)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? String == "top_tickers")
        let payload = try #require(object["top_tickers"] as? [String: Any])
        let tickers = try #require(payload["tickers"] as? [[String: Any]])
        #expect(tickers[0]["symbol"] as? String == "AAPL")
    }

    @Test
    func `unknown slide type fails to decode`() {
        let json = Data(#"{"type":"confetti"}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RecapSlide.self, from: json) }
    }

    @Test
    func `privacy flags cover only money slides`() {
        let privateCases = Self.samples.filter(\.isPrivate)
        #expect(privateCases == [Self.samples[5], Self.samples[6], Self.samples[7]])
    }

    @Test
    func `share card has no money or name fields`() {
        let card = RecapShareCard(
            kind: .month,
            periodLabel: "October 2026",
            archetype: .researcher,
            longestStreakDays: 7,
            tickersResearched: 5,
            badgesEarned: 2
        )
        let labels = Mirror(reflecting: card).children.compactMap(\.label)
        #expect(labels == [
            "kind",
            "periodLabel",
            "archetype",
            "longestStreakDays",
            "tickersResearched",
            "badgesEarned",
        ])
    }

    @Test
    func `archetype copy is complete`() {
        #expect(RecapArchetype.allCases.count == 9)
        for archetype in RecapArchetype.allCases {
            #expect(!archetype.title.isEmpty)
            #expect(!archetype.tagline.isEmpty)
        }
    }

    @Test
    func `deck and response round trip`() throws {
        let deck = RecapDeck(
            kind: .month, key: "2026-10", periodLabel: "October 2026", archetype: .saver,
            isFirstChapter: false, isMissedYou: false, slides: Self.samples, schemaVersion: 1
        )
        let response = RecapResponse(
            id: UUID(), deck: deck, generatedAt: Date(timeIntervalSince1970: 1000), openedAt: nil, completedAt: nil
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecapResponse.self, from: encoder.encode(response))
        #expect(decoded == response)
    }
}
