import Foundation

public struct Holding: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var symbol: AssetSymbol
    public var quantity: Decimal
    public var averageBuyPrice: Decimal?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        symbol: AssetSymbol,
        quantity: Decimal,
        averageBuyPrice: Decimal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.averageBuyPrice = averageBuyPrice
        self.createdAt = createdAt
    }
}
