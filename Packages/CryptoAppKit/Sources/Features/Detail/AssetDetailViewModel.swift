import Domain
import Foundation
import Observation
import PriceFeed

@MainActor
@Observable
public final class AssetDetailViewModel {
    public let asset: Asset
    public private(set) var chartState: LoadState<[PricePoint]> = .loading
    /// Number of times a *manual* Retry has ended in failure. Drives the red
    /// "still can't connect" hint under the button so the tap has visible feedback
    /// even when the chart lands back in the same `.failed` state.
    public private(set) var retryFailedCount = 0
    public private(set) var currentPrice: Decimal
    public private(set) var movement: PriceMovement = .flat
    public private(set) var changePercent24h: Decimal
    public private(set) var high24h: Decimal
    public private(set) var low24h: Decimal
    public private(set) var quoteVolume24h: Decimal
    public private(set) var feedStatus: FeedStatus = .connecting
    public private(set) var timeframe: Timeframe = .hour

    private static let liveWindow: TimeInterval = 65 * 60
    private let feed: LiveMarketFeed
    private let marketData: any MarketDataProviding
    @ObservationIgnored private var streamConsumer: Task<Void, Never>?
    @ObservationIgnored private var historyLoader: Task<Void, Never>?
    @ObservationIgnored private var countNextFailureAsRetry = false

    public init(row: MarketsViewModel.Row, dependencies: AppDependencies) {
        asset = row.asset
        currentPrice = row.price
        changePercent24h = row.changePercent24h
        high24h = row.high24h
        low24h = row.low24h
        quoteVolume24h = row.quoteVolume24h
        feed = dependencies.feed
        marketData = dependencies.marketData
    }

    deinit {
        streamConsumer?.cancel()
        historyLoader?.cancel()
    }

    public func activate() async {
        guard streamConsumer == nil else { return }
        startConsumingTicks()
        await loadHistory()
    }

    public func select(_ timeframe: Timeframe) {
        guard timeframe != self.timeframe else { return }
        self.timeframe = timeframe
        reloadHistory()
    }

    public func retryHistory() {
        countNextFailureAsRetry = true
        reloadHistory()
    }

    private func reloadHistory() {
        historyLoader?.cancel()
        historyLoader = Task { await loadHistory() }
    }

    private func loadHistory() async {
        let isRetry = countNextFailureAsRetry
        countNextFailureAsRetry = false
        chartState = .loading
        do {
            let points = try await marketData.history(for: asset.symbol, timeframe: timeframe)
            guard !Task.isCancelled else { return }
            chartState = .loaded(points)
            retryFailedCount = 0
        } catch {
            guard !Task.isCancelled else { return }
            chartState = .failed(message: "The chart couldn't be loaded right now.")
            if isRetry { retryFailedCount += 1 }
        }
    }

    private func startConsumingTicks() {
        streamConsumer = Task {
            let events = await feed.events()
            for await event in events {
                switch event {
                case .status(let status):
                    let recoveredConnection = status == .live && feedStatus != .live
                    feedStatus = status
                    // When the feed comes back after a drop, silently reload a
                    // chart that failed while offline — the same way live ticks
                    // resume — so the user doesn't have to tap Retry themselves.
                    if recoveredConnection, case .failed = chartState {
                        reloadHistory()
                    }
                case .tick(let tick):
                    apply(tick)
                }
            }
        }
    }

    private func apply(_ tick: PriceTick) {
        guard tick.symbol == asset.symbol else { return }
        movement = PriceMovement(from: currentPrice, to: tick.price)
        currentPrice = tick.price
        guard timeframe.supportsLiveAppend, case .loaded(var points) = chartState else { return }
        points.append(PricePoint(timestamp: tick.timestamp, price: tick.price))
        let cutoff = tick.timestamp.addingTimeInterval(-Self.liveWindow)
        if let first = points.first, first.timestamp < cutoff {
            points.removeAll { $0.timestamp < cutoff }
        }
        chartState = .loaded(points)
    }
}
