import Domain
import Foundation

public struct MockMarketData: MarketDataProviding {
    private let simulatedLatency: Duration

    public init(simulatedLatency: Duration = .milliseconds(350)) {
        self.simulatedLatency = simulatedLatency
    }

    public func snapshots(for symbols: [AssetSymbol]) async throws -> [MarketSnapshot] {
        try? await Task.sleep(for: simulatedLatency)
        return symbols.map { symbol in
            let base = MockBasePrices.price(for: symbol)
            var generator = SeededRandomGenerator(seed: Self.seed(symbol.rawValue))
            let changePercent = Double.random(in: -6...6, using: &generator)
            return MarketSnapshot(
                symbol: symbol,
                lastPrice: Self.decimal(base),
                changePercent24h: Self.decimal(changePercent),
                high24h: Self.decimal(base * 1.04),
                low24h: Self.decimal(base * 0.95),
                quoteVolume24h: Self.decimal(base * Double.random(in: 9_000...80_000, using: &generator))
            )
        }
    }

    public func history(for symbol: AssetSymbol, timeframe: Timeframe) async throws -> [PricePoint] {
        try? await Task.sleep(for: simulatedLatency)
        let (interval, limit) = BinanceMarketAPI.klineQuery(for: timeframe)
        let stepSeconds: TimeInterval = switch interval {
        case "1m": 60
        case "15m": 900
        default: 3600
        }
        var generator = SeededRandomGenerator(seed: Self.seed(symbol.rawValue + timeframe.rawValue))
        var price = MockBasePrices.price(for: symbol)
        let end = Date()
        var points: [PricePoint] = []
        for index in stride(from: limit - 1, through: 0, by: -1) {
            points.append(
                PricePoint(
                    timestamp: end.addingTimeInterval(-Double(index) * stepSeconds),
                    price: Self.decimal(price)
                )
            )
            price *= 1 + Double.random(in: -0.004...0.004, using: &generator)
        }
        return points
    }

    private static func seed(_ text: String) -> UInt64 {
        text.utf8.reduce(UInt64(1469598103934665603)) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    private static func decimal(_ value: Double) -> Decimal {
        Decimal(apiString: String(format: "%.8f", value)) ?? Decimal(value)
    }
}
