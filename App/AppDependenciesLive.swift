import Domain
import Features
import Persistence
import PriceFeed

extension AppDependencies {
    static func live() -> AppDependencies {
        AppDependencies(
            feed: LiveMarketFeed(
                streaming: BinancePriceStream(),
                symbols: AssetCatalog.tracked.map(\.symbol)
            ),
            marketData: BinanceMarketAPI(),
            portfolio: PortfolioStore(persistence: FilePortfolioPersistence())
        )
    }
}
