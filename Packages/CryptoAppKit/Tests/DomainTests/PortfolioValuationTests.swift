import Domain
import Foundation
import Testing

@Suite("Portfolio valuation math")
struct PortfolioValuationTests {
    private let btc = AssetSymbol("BTCUSDT")
    private let eth = AssetSymbol("ETHUSDT")

    @Test("Values are exact under Decimal arithmetic")
    func decimalExactness() {
        let valuation = PortfolioValuation(
            holdings: [Holding(symbol: btc, quantity: 3)],
            prices: [btc: Decimal(string: "0.1")!]
        )
        #expect(valuation.totalValue == Decimal(string: "0.3")!)
    }

    @Test("Total value sums quantity times price across holdings")
    func totalValue() {
        let valuation = PortfolioValuation(
            holdings: [
                Holding(symbol: btc, quantity: Decimal(string: "0.5")!),
                Holding(symbol: eth, quantity: 4),
            ],
            prices: [btc: 60_000, eth: 3_000]
        )
        #expect(valuation.totalValue == 42_000)
    }

    @Test("Absolute and relative return derive from cost basis")
    func profitAndLoss() throws {
        let valuation = PortfolioValuation(
            holdings: [Holding(symbol: btc, quantity: 2, averageBuyPrice: 50_000)],
            prices: [btc: 60_000]
        )
        #expect(valuation.totalCost == 100_000)
        #expect(valuation.totalReturn == 20_000)
        let relative = try #require(valuation.totalRelativeReturn)
        #expect(relative == Decimal(string: "0.2")!)
    }

    @Test("Holdings without a buy price contribute value but no return")
    func missingCostBasis() {
        let valuation = PortfolioValuation(
            holdings: [
                Holding(symbol: btc, quantity: 1, averageBuyPrice: 50_000),
                Holding(symbol: eth, quantity: 10),
            ],
            prices: [btc: 60_000, eth: 3_000]
        )
        #expect(valuation.totalValue == 90_000)
        #expect(valuation.totalCost == 50_000)
        #expect(valuation.totalReturn == 10_000)
    }

    @Test("An unpriced holding is excluded from the total and flagged")
    func unpricedHolding() {
        let valuation = PortfolioValuation(
            holdings: [
                Holding(symbol: btc, quantity: 1),
                Holding(symbol: eth, quantity: 5),
            ],
            prices: [btc: 60_000]
        )
        #expect(valuation.totalValue == 60_000)
        #expect(!valuation.isFullyPriced)
    }

    @Test("Position weights sum to one when everything is priced")
    func weights() throws {
        let valuation = PortfolioValuation(
            holdings: [
                Holding(symbol: btc, quantity: 1),
                Holding(symbol: eth, quantity: 10),
            ],
            prices: [btc: 75_000, eth: 2_500]
        )
        let weights = try valuation.positions.map { try #require(valuation.weight(of: $0)) }
        #expect(weights.reduce(0, +) == 1)
        #expect(weights[0] == Decimal(string: "0.75")!)
    }

    @Test("Empty portfolio values to zero without derived returns")
    func emptyPortfolio() {
        let valuation = PortfolioValuation(holdings: [], prices: [:])
        #expect(valuation.totalValue == 0)
        #expect(valuation.totalCost == nil)
        #expect(valuation.totalReturn == nil)
        #expect(valuation.isFullyPriced)
    }
}
