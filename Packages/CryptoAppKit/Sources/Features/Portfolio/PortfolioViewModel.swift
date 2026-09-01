import Domain
import Foundation
import Observation
import Persistence
import PriceFeed

@MainActor
@Observable
public final class PortfolioViewModel {
    public private(set) var holdings: [Holding]?
    public private(set) var prices: [AssetSymbol: Decimal] = [:]
    public private(set) var movements: [AssetSymbol: PriceMovement] = [:]
    public private(set) var feedStatus: FeedStatus = .connecting
    public var errorMessage: String?

    private let feed: LiveMarketFeed
    private let store: PortfolioStore
    @ObservationIgnored private var streamConsumer: Task<Void, Never>?

    public init(dependencies: AppDependencies) {
        feed = dependencies.feed
        store = dependencies.portfolio
    }

    deinit {
        streamConsumer?.cancel()
    }

    public var valuation: PortfolioValuation? {
        holdings.map { PortfolioValuation(holdings: $0, prices: prices) }
    }

    /// Safe to call on every appearance: the stream subscription is created
    /// once, while holdings re-sync so additions made elsewhere show up.
    public func activate() async {
        startConsumingTicks()
        await refreshHoldings()
    }

    public func refreshHoldings() async {
        holdings = await store.holdings()
    }

    public func remove(_ holding: Holding) async {
        do {
            try await store.remove(holdingID: holding.id)
            holdings = await store.holdings()
        } catch {
            errorMessage = "We couldn't delete that holding. Please try again."
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
                    movements[tick.symbol] = PriceMovement(from: prices[tick.symbol], to: tick.price)
                    prices[tick.symbol] = tick.price
                }
            }
        }
    }
}
