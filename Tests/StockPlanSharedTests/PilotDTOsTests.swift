import Foundation
import StockPlanShared
import Testing

@Suite("PilotDTOs")
struct PilotDTOsTests {
    @Test("follow request round-trips with camelCase keys")
    func createRequestRoundTrip() throws {
        let request = PilotFollowCreateRequest(
            pilotSlug: "nancy-pelosi",
            targetKind: .portfolio,
            portfolioListId: nil,
            watchlistListId: nil,
            startingCapital: 10_000
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"pilotSlug\":\"nancy-pelosi\""))
        #expect(json.contains("\"targetKind\":\"portfolio\""))
        #expect(try JSONDecoder().decode(PilotFollowCreateRequest.self, from: data) == request)
    }

    @Test("watchlist status decodes exited")
    func exitedStatus() throws {
        let decoded = try JSONDecoder().decode([WatchlistStatus].self, from: Data("[\"exited\"]".utf8))
        #expect(decoded == [.exited])
    }
}
