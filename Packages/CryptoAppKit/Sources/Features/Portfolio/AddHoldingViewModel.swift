import Domain
import Foundation
import Observation
import Persistence

@MainActor
@Observable
final class AddHoldingViewModel {
    var selectedAsset: Asset
    var quantityText = ""
    var buyPriceText = ""
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let portfolio: PortfolioStore

    init(portfolio: PortfolioStore, preselectedAsset: Asset? = nil) {
        self.portfolio = portfolio
        selectedAsset = preselectedAsset ?? AssetCatalog.tracked[0]
    }

    var parsedQuantity: Decimal? {
        DecimalInput.parsePositive(quantityText)
    }

    var parsedBuyPrice: Decimal? {
        DecimalInput.parsePositive(buyPriceText)
    }

    var canSave: Bool {
        parsedQuantity != nil
            && (buyPriceText.isEmpty || parsedBuyPrice != nil)
            && !isSaving
    }

    func save() async -> Bool {
        guard let quantity = parsedQuantity else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await portfolio.upsert(
                Holding(
                    symbol: selectedAsset.symbol,
                    quantity: quantity,
                    averageBuyPrice: buyPriceText.isEmpty ? nil : parsedBuyPrice
                )
            )
            return true
        } catch {
            errorMessage = "We couldn't save this holding. Please try again."
            return false
        }
    }
}
