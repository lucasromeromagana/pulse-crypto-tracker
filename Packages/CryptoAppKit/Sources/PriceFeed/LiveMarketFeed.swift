import Domain
import Foundation

/// Owns the single upstream socket subscription and fans events out to any
/// number of screens. The actor serializes access to the subscriber registry
/// and the latest-price cache, which are written by the pump task while being
/// read and mutated from the main actor as screens come and go.
public actor LiveMarketFeed {
    private let streaming: any PriceStreaming
    private let symbols: [AssetSymbol]
    private var subscribers: [UUID: AsyncStream<PriceFeedEvent>.Continuation] = [:]
    private var latestTicks: [AssetSymbol: PriceTick] = [:]
    private var currentStatus: FeedStatus = .connecting
    private var pump: Task<Void, Never>?

    public init(streaming: any PriceStreaming, symbols: [AssetSymbol]) {
        self.streaming = streaming
        self.symbols = symbols
    }

    deinit {
        pump?.cancel()
    }

    /// New subscribers immediately receive the current status and the last
    /// known tick per symbol, so a screen opened mid-session renders live data
    /// without waiting for the next frame from upstream.
    public func events() -> AsyncStream<PriceFeedEvent> {
        startPumpIfNeeded()
        let (stream, continuation) = AsyncStream.makeStream(
            of: PriceFeedEvent.self,
            bufferingPolicy: .bufferingNewest(256)
        )
        let id = UUID()
        subscribers[id] = continuation
        continuation.yield(.status(currentStatus))
        for tick in latestTicks.values {
            continuation.yield(.tick(tick))
        }
        continuation.onTermination = { _ in
            Task { await self.removeSubscriber(id) }
        }
        return stream
    }

    public func latestPrices() -> [AssetSymbol: Decimal] {
        latestTicks.mapValues(\.price)
    }

    private func startPumpIfNeeded() {
        guard pump == nil else { return }
        pump = Task {
            for await event in streaming.events(for: symbols) {
                ingest(event)
            }
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    private func ingest(_ event: PriceFeedEvent) {
        switch event {
        case .status(let status):
            currentStatus = status
        case .tick(let tick):
            latestTicks[tick.symbol] = tick
        }
        for continuation in subscribers.values {
            continuation.yield(event)
        }
    }
}
