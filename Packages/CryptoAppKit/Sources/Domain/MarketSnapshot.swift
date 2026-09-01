import Foundation

public struct MarketSnapshot: Hashable, Sendable {
    public let symbol: AssetSymbol
    public let lastPrice: Decimal
    public let changePercent24h: Decimal
    public let high24h: Decimal
    public let low24h: Decimal
    public let quoteVolume24h: Decimal

    public init(
        symbol: AssetSymbol,
        lastPrice: Decimal,
        changePercent24h: Decimal,
        high24h: Decimal,
        low24h: Decimal,
        quoteVolume24h: Decimal
    ) {
        self.symbol = symbol
        self.lastPrice = lastPrice
        self.changePercent24h = changePercent24h
        self.high24h = high24h
        self.low24h = low24h
        self.quoteVolume24h = quoteVolume24h
    }
}
