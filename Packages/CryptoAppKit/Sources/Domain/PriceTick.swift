import Foundation

public struct PriceTick: Hashable, Sendable {
    public let symbol: AssetSymbol
    public let price: Decimal
    public let timestamp: Date

    public init(symbol: AssetSymbol, price: Decimal, timestamp: Date) {
        self.symbol = symbol
        self.price = price
        self.timestamp = timestamp
    }
}

public enum PriceMovement: Hashable, Sendable {
    case up
    case down
    case flat

    public init(from old: Decimal?, to new: Decimal) {
        guard let old else {
            self = .flat
            return
        }
        if new > old {
            self = .up
        } else if new < old {
            self = .down
        } else {
            self = .flat
        }
    }
}
