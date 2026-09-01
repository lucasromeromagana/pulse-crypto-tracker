import Domain
@testable import Features
import Foundation
import Persistence
import PriceFeed
import Testing

@MainActor
@Suite("Portfolio view model")
struct PortfolioViewModelTests {
    @Test("Holdings load on activation and value follows live ticks")
    func liveValuation() async {
        let upstream = ControlledPriceStream()
        let persistence = InMemoryPortfolioPersistence(initial: [
            Holding(symbol: Fixtures.bitcoin.symbol, quantity: 2)
        ])
        let viewModel = PortfolioViewModel(
            dependencies: Fixtures.dependencies(upstream: upstream, persistence: persistence)
        )
        #expect(viewModel.valuation == nil)

        await viewModel.activate()
        #expect(viewModel.valuation?.positions.count == 1)
        #expect(viewModel.valuation?.isFullyPriced == false)

        upstream.send(.tick(Fixtures.tick(for: Fixtures.bitcoin.symbol, price: 60_000)))

        let updated = await expectEventually {
            viewModel.valuation?.totalValue == 120_000
        }
        #expect(updated)
        #expect(viewModel.valuation?.isFullyPriced == true)
    }

    @Test("Removing a holding updates state; a failed delete surfaces an error")
    func removal() async throws {
        let persistence = InMemoryPortfolioPersistence(initial: [
            Holding(symbol: Fixtures.bitcoin.symbol, quantity: 1),
            Holding(symbol: Fixtures.ethereum.symbol, quantity: 5),
        ])
        let viewModel = PortfolioViewModel(
            dependencies: Fixtures.dependencies(persistence: persistence)
        )
        await viewModel.activate()
        let holdings = try #require(viewModel.holdings)

        await viewModel.remove(holdings[0])
        #expect(viewModel.holdings?.count == 1)
        #expect(viewModel.errorMessage == nil)

        persistence.stub(nextSaveError: CocoaError(.fileWriteNoPermission))
        await viewModel.remove(holdings[1])
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.holdings?.count == 1)
    }
}
