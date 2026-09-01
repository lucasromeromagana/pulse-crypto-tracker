import Domain
@testable import Features
import Foundation
import Persistence
import Testing

@MainActor
@Suite("Add holding input and save flow")
struct AddHoldingViewModelTests {
    private func makeViewModel(
        persistence: InMemoryPortfolioPersistence = InMemoryPortfolioPersistence()
    ) -> (AddHoldingViewModel, PortfolioStore) {
        let store = PortfolioStore(persistence: persistence)
        let viewModel = AddHoldingViewModel(portfolio: store, preselectedAsset: Fixtures.bitcoin)
        return (viewModel, store)
    }

    @Test("Comma decimals parse — European keyboards are first-class")
    func commaParsing() async throws {
        let (viewModel, store) = makeViewModel()
        viewModel.quantityText = "0,5"
        #expect(viewModel.canSave)

        #expect(await viewModel.save())
        let holdings = await store.holdings()
        #expect(holdings.count == 1)
        #expect(holdings[0].quantity == Decimal(string: "0.5")!)
        #expect(holdings[0].averageBuyPrice == nil)
    }

    @Test("Invalid quantities can't be saved", arguments: ["", "abc", "0", "-3", "1.2.3"])
    func invalidQuantity(text: String) {
        let (viewModel, _) = makeViewModel()
        viewModel.quantityText = text
        #expect(!viewModel.canSave)
    }

    @Test("Buy price is optional, but if present it must be valid")
    func buyPriceValidation() {
        let (viewModel, _) = makeViewModel()
        viewModel.quantityText = "1"
        #expect(viewModel.canSave)

        viewModel.buyPriceText = "not a number"
        #expect(!viewModel.canSave)

        viewModel.buyPriceText = "58000.50"
        #expect(viewModel.canSave)
    }

    @Test("A failed save reports an error instead of dismissing silently")
    func failedSave() async {
        let persistence = InMemoryPortfolioPersistence()
        persistence.stub(nextSaveError: CocoaError(.fileWriteNoPermission))
        let (viewModel, store) = makeViewModel(persistence: persistence)
        viewModel.quantityText = "1"

        #expect(await viewModel.save() == false)
        #expect(viewModel.errorMessage != nil)
        #expect(await store.holdings().isEmpty)
    }
}

@Suite("Decimal input parsing")
struct DecimalInputTests {
    @Test("Valid inputs", arguments: [
        ("0.5", "0.5"),
        ("0,5", "0.5"),
        (" 42 ", "42"),
        ("0.00000001", "0.00000001"),
    ])
    func parses(input: String, expected: String) {
        #expect(DecimalInput.parse(input) == Decimal(string: expected)!)
    }

    @Test("Invalid inputs", arguments: ["", "  ", "abc", "1..2"])
    func rejects(input: String) {
        #expect(DecimalInput.parse(input) == nil)
    }

    @Test("parsePositive rejects zero and negatives", arguments: ["0", "-1", "-0,5"])
    func rejectsNonPositive(input: String) {
        #expect(DecimalInput.parsePositive(input) == nil)
    }
}
