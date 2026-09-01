import Domain
import Features
import Foundation
import Persistence
import PriceFeed

struct ControlledPriceStream: PriceStreaming {
    private let stream: AsyncStream<PriceFeedEvent>
    private let continuation: AsyncStream<PriceFeedEvent>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(
            of: PriceFeedEvent.self,
            bufferingPolicy: .bufferingNewest(256)
        )
    }

    func events(for symbols: [AssetSymbol]) -> AsyncStream<PriceFeedEvent> {
        stream
    }

    func send(_ event: PriceFeedEvent) {
        continuation.yield(event)
    }
}

final class MutableStubMarketData: MarketDataProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _snapshotsResult: Result<[MarketSnapshot], MarketDataError>
    private var _historyResult: Result<[PricePoint], MarketDataError>

    init(
        snapshotsResult: Result<[MarketSnapshot], MarketDataError> = .success([]),
        historyResult: Result<[PricePoint], MarketDataError> = .success([])
    ) {
        _snapshotsResult = snapshotsResult
        _historyResult = historyResult
    }

    var snapshotsResult: Result<[MarketSnapshot], MarketDataError> {
        get { lock.withLock { _snapshotsResult } }
        set { lock.withLock { _snapshotsResult = newValue } }
    }

    var historyResult: Result<[PricePoint], MarketDataError> {
        get { lock.withLock { _historyResult } }
        set { lock.withLock { _historyResult = newValue } }
    }

    func snapshots(for symbols: [AssetSymbol]) async throws -> [MarketSnapshot] {
        try snapshotsResult.get()
    }

    func history(for symbol: AssetSymbol, timeframe: Timeframe) async throws -> [PricePoint] {
        try historyResult.get()
    }
}

enum Fixtures {
    static let bitcoin = AssetCatalog.tracked[0]
    static let ethereum = AssetCatalog.tracked[1]

    static func snapshot(
        for symbol: AssetSymbol,
        price: Decimal,
        changePercent: Decimal = Decimal(string: "2.5")!
    ) -> MarketSnapshot {
        MarketSnapshot(
            symbol: symbol,
            lastPrice: price,
            changePercent24h: changePercent,
            high24h: price * 2,
            low24h: price / 2,
            quoteVolume24h: 1_000_000
        )
    }

    static func tick(for symbol: AssetSymbol, price: Decimal) -> PriceTick {
        PriceTick(symbol: symbol, price: price, timestamp: Date())
    }

    static func dependencies(
        upstream: ControlledPriceStream = ControlledPriceStream(),
        marketData: MutableStubMarketData = MutableStubMarketData(),
        persistence: InMemoryPortfolioPersistence = InMemoryPortfolioPersistence()
    ) -> AppDependencies {
        AppDependencies(
            feed: LiveMarketFeed(
                streaming: upstream,
                symbols: AssetCatalog.tracked.map(\.symbol)
            ),
            marketData: marketData,
            portfolio: PortfolioStore(persistence: persistence)
        )
    }
}

@MainActor
func expectEventually(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}
