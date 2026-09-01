import Domain
@testable import Features
import Foundation
import PriceFeed
import Testing

@MainActor
@Suite("Markets view model state machine")
struct MarketsViewModelTests {
    @Test("Starts in loading and transitions to loaded rows in catalog order")
    func loadSuccess() async {
        let marketData = MutableStubMarketData(
            snapshotsResult: .success([
                Fixtures.snapshot(for: Fixtures.bitcoin.symbol, price: 67_000),
                Fixtures.snapshot(for: Fixtures.ethereum.symbol, price: 3_500),
            ])
        )
        let viewModel = MarketsViewModel(
            dependencies: Fixtures.dependencies(marketData: marketData),
            assets: [Fixtures.bitcoin, Fixtures.ethereum]
        )
        #expect(viewModel.state == .loading)

        await viewModel.activate()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("Expected loaded state, got \(viewModel.state)")
            return
        }
        #expect(rows.map(\.asset.code) == ["BTC", "ETH"])
        #expect(rows[0].price == 67_000)
    }

    @Test("A snapshot failure produces a user-facing error, and retry recovers")
    func failureThenRetry() async {
        let marketData = MutableStubMarketData(snapshotsResult: .failure(.badStatus(500)))
        let viewModel = MarketsViewModel(
            dependencies: Fixtures.dependencies(marketData: marketData),
            assets: [Fixtures.bitcoin]
        )

        await viewModel.activate()
        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)

        marketData.snapshotsResult = .success([
            Fixtures.snapshot(for: Fixtures.bitcoin.symbol, price: 67_000)
        ])
        await viewModel.retry()
        #expect(viewModel.state.value?.count == 1)
    }

    @Test("A live tick updates the row's price and movement direction")
    func tickUpdatesRow() async {
        let upstream = ControlledPriceStream()
        let marketData = MutableStubMarketData(
            snapshotsResult: .success([
                Fixtures.snapshot(for: Fixtures.bitcoin.symbol, price: 67_000)
            ])
        )
        let viewModel = MarketsViewModel(
            dependencies: Fixtures.dependencies(upstream: upstream, marketData: marketData),
            assets: [Fixtures.bitcoin]
        )
        await viewModel.activate()

        upstream.send(.tick(Fixtures.tick(for: Fixtures.bitcoin.symbol, price: 67_500)))

        let updated = await expectEventually {
            viewModel.state.value?.first?.price == 67_500
        }
        #expect(updated)
        #expect(viewModel.state.value?.first?.movement == .up)
    }

    @Test("Feed status events reach the view model")
    func feedStatus() async {
        let upstream = ControlledPriceStream()
        let marketData = MutableStubMarketData(
            snapshotsResult: .success([
                Fixtures.snapshot(for: Fixtures.bitcoin.symbol, price: 67_000)
            ])
        )
        let viewModel = MarketsViewModel(
            dependencies: Fixtures.dependencies(upstream: upstream, marketData: marketData),
            assets: [Fixtures.bitcoin]
        )
        await viewModel.activate()

        upstream.send(.status(.reconnecting(attempt: 2)))

        let updated = await expectEventually {
            viewModel.feedStatus == .reconnecting(attempt: 2)
        }
        #expect(updated)
    }
}
