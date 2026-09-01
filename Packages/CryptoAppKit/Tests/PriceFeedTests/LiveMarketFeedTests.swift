import Domain
import Foundation
import PriceFeed
import Testing

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

@Suite("LiveMarketFeed multicast")
struct LiveMarketFeedTests {
    private let btc = AssetSymbol("BTCUSDT")

    private func firstTick(in stream: AsyncStream<PriceFeedEvent>) async -> PriceTick? {
        for await event in stream {
            if case .tick(let tick) = event { return tick }
        }
        return nil
    }

    @Test("One upstream tick reaches every subscriber")
    func multicast() async {
        let upstream = ControlledPriceStream()
        let feed = LiveMarketFeed(streaming: upstream, symbols: [btc])
        let firstSubscriber = await feed.events()
        let secondSubscriber = await feed.events()

        let tick = PriceTick(symbol: btc, price: 67_000, timestamp: Date(timeIntervalSince1970: 1_700_000_000))
        upstream.send(.tick(tick))

        #expect(await firstTick(in: firstSubscriber) == tick)
        #expect(await firstTick(in: secondSubscriber) == tick)
    }

    @Test("A late subscriber is replayed the latest known tick immediately")
    func lateSubscriberReplay() async {
        let upstream = ControlledPriceStream()
        let feed = LiveMarketFeed(streaming: upstream, symbols: [btc])
        let earlySubscriber = await feed.events()

        let tick = PriceTick(symbol: btc, price: 66_500, timestamp: Date(timeIntervalSince1970: 1_700_000_000))
        upstream.send(.tick(tick))
        _ = await firstTick(in: earlySubscriber)

        let lateSubscriber = await feed.events()
        #expect(await firstTick(in: lateSubscriber) == tick)
    }

    @Test("Status updates propagate to subscribers")
    func statusPropagation() async {
        let upstream = ControlledPriceStream()
        let feed = LiveMarketFeed(streaming: upstream, symbols: [btc])
        let subscriber = await feed.events()
        upstream.send(.status(.live))

        var statuses: [FeedStatus] = []
        for await event in subscriber {
            if case .status(let status) = event {
                statuses.append(status)
                if status == .live { break }
            }
        }
        #expect(statuses.last == .live)
    }
}
