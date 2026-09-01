import Foundation

public struct HoldingValuation: Identifiable, Hashable, Sendable {
    public let holding: Holding
    public let currentPrice: Decimal?

    public var id: UUID { holding.id }

    public var marketValue: Decimal? {
        currentPrice.map { $0 * holding.quantity }
    }

    public var cost: Decimal? {
        holding.averageBuyPrice.map { $0 * holding.quantity }
    }

    public var absoluteReturn: Decimal? {
        guard let marketValue, let cost else { return nil }
        return marketValue - cost
    }

    public var relativeReturn: Decimal? {
        guard let absoluteReturn, let cost, cost > 0 else { return nil }
        return absoluteReturn / cost
    }

    public init(holding: Holding, currentPrice: Decimal?) {
        self.holding = holding
        self.currentPrice = currentPrice
    }
}

public struct PortfolioValuation: Hashable, Sendable {
    public let positions: [HoldingValuation]

    public init(holdings: [Holding], prices: [AssetSymbol: Decimal]) {
        positions = holdings.map {
            HoldingValuation(holding: $0, currentPrice: prices[$0.symbol])
        }
    }

    public var totalValue: Decimal {
        positions.compactMap(\.marketValue).reduce(0, +)
    }

    public var totalCost: Decimal? {
        let costs = positions.compactMap(\.cost)
        return costs.isEmpty ? nil : costs.reduce(0, +)
    }

    public var totalReturn: Decimal? {
        let returns = positions.compactMap(\.absoluteReturn)
        return returns.isEmpty ? nil : returns.reduce(0, +)
    }

    public var totalRelativeReturn: Decimal? {
        guard let totalReturn, let totalCost, totalCost > 0 else { return nil }
        return totalReturn / totalCost
    }

    /// False while any position still awaits its first price, so the UI can
    /// show a partial total honestly instead of presenting it as final.
    public var isFullyPriced: Bool {
        positions.allSatisfy { $0.currentPrice != nil }
    }

    public func weight(of position: HoldingValuation) -> Decimal? {
        guard let value = position.marketValue, totalValue > 0 else { return nil }
        return value / totalValue
    }
}
