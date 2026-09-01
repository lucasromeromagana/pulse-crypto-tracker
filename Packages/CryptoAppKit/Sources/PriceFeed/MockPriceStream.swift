import Domain
import Foundation

/// A believable random-walk feed with the same contract as the Binance stream,
/// used by previews, offline demos, and as a swap-in when the network is down.
public struct MockPriceStream: PriceStreaming {
    private let tickInterval: Duration

    public init(tickInterval: Duration = .milliseconds(850)) {
        self.tickInterval = tickInterval
    }

    public func events(for symbols: [AssetSymbol]) -> AsyncStream<PriceFeedEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(256)) { continuation in
            let feedLoop = Task {
                continuation.yield(.status(.connecting))
                try? await Task.sleep(for: .milliseconds(400))
                continuation.yield(.status(.live))

                var prices = Dictionary(
                    uniqueKeysWithValues: symbols.map { ($0, MockBasePrices.price(for: $0)) }
                )
                while !Task.isCancelled {
                    try? await Task.sleep(for: tickInterval)
                    guard !Task.isCancelled else { break }
                    for symbol in symbols where Double.random(in: 0...1) < 0.6 {
                        let drift = Double.random(in: -0.0018...0.0018)
                        let updated = (prices[symbol] ?? 100) * (1 + drift)
                        prices[symbol] = updated
                        if let price = Decimal(apiString: String(format: "%.8f", updated)) {
                            continuation.yield(
                                .tick(PriceTick(symbol: symbol, price: price, timestamp: Date()))
                            )
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in feedLoop.cancel() }
        }
    }
}

enum MockBasePrices {
    static let byCode: [String: Double] = [
        "BTC": 67_240, "ETH": 3_485, "SOL": 158.4, "BNB": 592.1,
        "XRP": 0.6215, "ADA": 0.4482, "DOGE": 0.1418, "AVAX": 29.85,
        "DOT": 6.52, "LINK": 14.92, "LTC": 74.6, "UNI": 8.43,
    ]

    static func price(for symbol: AssetSymbol) -> Double {
        let code = symbol.rawValue.replacingOccurrences(of: "USDT", with: "")
        return byCode[code] ?? 100
    }
}
