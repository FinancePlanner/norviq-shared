import Foundation
import Testing
@testable import StockPlanShared

struct TerminalMathTests {
    private func success(_ input: TerminalScenarioInput) throws -> TerminalScenarioResult {
        try TerminalMath.evaluate(input).get()
    }

    @Test
    func `AMZN: 10T cap on 11B shares is 909.09 and a 1M target needs 1100 shares`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 11_000_000_000, terminalMarketCap: 10_000_000_000_000, valueWanted: 1_000_000
        ))
        #expect(abs(result.terminalSharePrice - 909.090909090909) < 1e-9)
        #expect(abs(result.sharesNeeded - 1100) < 1e-9)
    }

    @Test
    func `VG: 12.5B cap on 200M shares is 62.5 and a 500k target needs 8000 shares`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 200_000_000, terminalMarketCap: 12_500_000_000, valueWanted: 500_000
        ))
        #expect(abs(result.terminalSharePrice - 62.5) < 1e-12)
        #expect(abs(result.sharesNeeded - 8000) < 1e-9)
    }

    @Test
    func `SOFI: 150B cap on 1.75B shares is 85.714 and a 250k target needs 2916.67 shares`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 1_750_000_000, terminalMarketCap: 150_000_000_000, valueWanted: 250_000
        ))
        #expect(abs(result.terminalSharePrice - 85.71428571) < 1e-8)
        #expect(abs(result.sharesNeeded - 2916.6667) < 1e-4)
    }

    @Test
    func `Owning 750 of 1100 needed is 68.18% progress, 350 still needed`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 11_000_000_000, terminalMarketCap: 10_000_000_000_000,
            valueWanted: 1_000_000, sharesOwned: 750, currentSharePrice: 200
        ))
        #expect(abs(result.progress - 0.681818181818) < 1e-9)
        #expect(abs(result.sharesStillNeeded - 350) < 1e-9)
        #expect(abs(result.gapValueAtTerminal - 350 * 909.090909090909) < 1e-6)
        #expect(abs((result.capitalAtTodayPrice ?? 0) - 220_000) < 1e-6)
    }

    @Test
    func `Owning more than needed caps still-needed at zero`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 200_000_000, terminalMarketCap: 12_500_000_000, valueWanted: 500_000, sharesOwned: 9000
        ))
        #expect(result.sharesStillNeeded == 0)
        #expect(result.gapValueAtTerminal == 0)
        #expect(result.progress > 1)
    }

    @Test
    func `A zero target needs zero shares and reports zero progress`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 200_000_000, terminalMarketCap: 12_500_000_000, valueWanted: 0, sharesOwned: 10
        ))
        #expect(result.sharesNeeded == 0)
        #expect(result.progress == 0)
    }

    @Test
    func `No current price means no capital at today's price`() throws {
        let result = try success(TerminalScenarioInput(
            terminalShareCount: 200_000_000, terminalMarketCap: 12_500_000_000, valueWanted: 500_000
        ))
        #expect(result.capitalAtTodayPrice == nil)
    }

    @Test
    func `Guardrails: non-positive share count or market cap never divides`() {
        #expect(TerminalMath.evaluate(TerminalScenarioInput(
            terminalShareCount: 0, terminalMarketCap: 1, valueWanted: 1
        )) == .failure(.shareCountNotPositive))
        #expect(TerminalMath.evaluate(TerminalScenarioInput(
            terminalShareCount: 1, terminalMarketCap: -5, valueWanted: 1
        )) == .failure(.marketCapNotPositive))
        #expect(TerminalMath.evaluate(TerminalScenarioInput(
            terminalShareCount: .nan, terminalMarketCap: 1, valueWanted: 1
        )) == .failure(.invalidNumber))
        #expect(TerminalMath.evaluate(TerminalScenarioInput(
            terminalShareCount: 1, terminalMarketCap: 1, valueWanted: -1
        )) == .failure(.invalidNumber))
    }

    @Test
    func `Round down to whole shares is display-only floor`() {
        #expect(TerminalMath.wholeShares(2916.6667) == 2916)
        #expect(TerminalMath.wholeShares(-3) == 0)
        #expect(TerminalMath.wholeShares(.infinity) == 0)
    }

    @Test
    func `Monthly equivalents follow the cadence`() {
        #expect(abs((AutobuyMath.monthlyEquivalent(amount: 50, cadence: .weekly, percent: nil) ?? 0) - 216.6666667) <
            1e-6)
        #expect(abs((AutobuyMath.monthlyEquivalent(amount: 100, cadence: .biweekly, percent: nil) ?? 0) - 216.6666667) <
            1e-6)
        #expect(AutobuyMath.monthlyEquivalent(amount: 275, cadence: .bimonthly, percent: nil) == 137.5)
        #expect(AutobuyMath.monthlyEquivalent(amount: 300, cadence: .monthly, percent: nil) == 300)
        #expect(AutobuyMath.monthlyEquivalent(amount: 5000, cadence: .percentOfContribution, percent: 0.04) == 200)
        #expect(AutobuyMath.monthlyEquivalent(amount: 0, cadence: .percentOfContribution, percent: 0.04) == nil)
        #expect(AutobuyMath.monthlyEquivalent(amount: 5000, cadence: .percentOfContribution, percent: nil) == nil)
        #expect(AutobuyMath.monthlyEquivalent(amount: 50, cadence: .unknown, percent: nil) == nil)
    }

    @Test
    func `Monthly total counts active rows with a known equivalent`() {
        let total = AutobuyMath.monthlyTotal([
            (amount: 50, cadence: .weekly, percent: nil, active: true),
            (amount: 275, cadence: .bimonthly, percent: nil, active: true),
            (amount: 1000, cadence: .monthly, percent: nil, active: false),
            (amount: 0, cadence: .percentOfContribution, percent: 0.04, active: true),
        ])
        #expect(abs(total - (216.6666667 + 137.5)) < 1e-6)
    }

    @Test
    func `Unknown cadence strings decode as unknown`() throws {
        let decoded = try JSONDecoder().decode([AutobuyCadence].self, from: Data(#"["weekly","fortnightly"]"#.utf8))
        #expect(decoded == [.weekly, .unknown])
    }
}
