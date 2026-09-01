import Domain
import Foundation
import Observation
import PriceFeed

@MainActor
@Observable
public final class MarketsViewModel {
    public struct Row: Identifiable, Hashable, Sendable {
        public let asset: Asset
        public var price: Decimal
        public var movement: PriceMovement
        public var changePercent24h: Decimal
        public var high24h: Decimal
        public var low24h: Decimal
        public var quoteVolume24h: Decimal

        public nonisolated var id: AssetSymbol { asset.symbol }
    }

    public private(set) var state: LoadState<[Row]> = .loading
    public private(set) var feedStatus: FeedStatus = .connecting

    private let assets: [Asset]
    private let feed: LiveMarketFeed
    private let marketData: any MarketDataProviding
    // @ObservationIgnored: implementation state, and required so the
    // nonisolated deinit can legally reach a genuinely *stored* property.
    @ObservationIgnored private var streamConsumer: Task<Void, Never>?

    public init(dependencies: AppDependencies, assets: [Asset] = AssetCatalog.tracked) {
        self.assets = assets
        feed = dependencies.feed
        marketData = dependencies.marketData
    }

    deinit {
        streamConsumer?.cancel()
    }

    public func activate() async {
        guard streamConsumer == nil else { return }
        await load()
    }

    public func retry() async {
        await load()
    }

    private func load() async {
        state = .loading
        do {
            let snapshots = try await marketData.snapshots(for: assets.map(\.symbol))
            let assetsBySymbol = Dictionary(uniqueKeysWithValues: assets.map { ($0.symbol, $0) })
            let rows = snapshots.compactMap { snapshot -> Row? in
                guard let asset = assetsBySymbol[snapshot.symbol] else { return nil }
                return Row(
                    asset: asset,
                    price: snapshot.lastPrice,
                    movement: .flat,
                    changePercent24h: snapshot.changePercent24h,
                    high24h: snapshot.high24h,
                    low24h: snapshot.low24h,
                    quoteVolume24h: snapshot.quoteVolume24h
                )
            }
            state = .loaded(rows)
            startConsumingTicks()
        } catch {
            state = .failed(message: "We couldn't load live market data. Check your connection and try again.")
        }
    }

    private func startConsumingTicks() {
        guard streamConsumer == nil else { return }
        streamConsumer = Task {
            let events = await feed.events()
            for await event in events {
                switch event {
                case .status(let status):
                    feedStatus = status
                case .tick(let tick):
                    apply(tick)
                }
            }
        }
    }

    private func apply(_ tick: PriceTick) {
        mutateRows { rows in
            guard let index = rows.firstIndex(where: { $0.id == tick.symbol }) else { return }
            rows[index].movement = PriceMovement(from: rows[index].price, to: tick.price)
            rows[index].price = tick.price
        }
    }

    private func mutateRows(_ transform: (inout [Row]) -> Void) {
        guard case .loaded(var rows) = state else { return }
        transform(&rows)
        state = .loaded(rows)
    }
}
