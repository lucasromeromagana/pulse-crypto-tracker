import Domain
import Persistence
import PriceFeed

/// The app target builds the live graph; previews and UI-level tests build a
/// mocked one. Hand-wired because at this scale a composition root beats any
/// DI framework: it's compile-time checked and there is nothing magic to debug.
public struct AppDependencies: Sendable {
    public let feed: LiveMarketFeed
    public let marketData: any MarketDataProviding
    public let portfolio: PortfolioStore

    public init(
        feed: LiveMarketFeed,
        marketData: any MarketDataProviding,
        portfolio: PortfolioStore
    ) {
        self.feed = feed
        self.marketData = marketData
        self.portfolio = portfolio
    }

    public static func mock() -> AppDependencies {
        AppDependencies(
            feed: LiveMarketFeed(
                streaming: MockPriceStream(),
                symbols: AssetCatalog.tracked.map(\.symbol)
            ),
            marketData: MockMarketData(),
            portfolio: PortfolioStore(
                persistence: InMemoryPortfolioPersistence(initial: [
                    Holding(symbol: AssetSymbol("BTCUSDT"), quantity: 0.5, averageBuyPrice: 58_000),
                    Holding(symbol: AssetSymbol("ETHUSDT"), quantity: 4, averageBuyPrice: 3_900),
                    Holding(symbol: AssetSymbol("SOLUSDT"), quantity: 25),
                ])
            )
        )
    }
}
