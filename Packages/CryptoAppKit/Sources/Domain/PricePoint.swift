import Foundation

public struct PricePoint: Hashable, Sendable, Identifiable {
    public let timestamp: Date
    public let price: Decimal

    public var id: Date { timestamp }

    public init(timestamp: Date, price: Decimal) {
        self.timestamp = timestamp
        self.price = price
    }
}

public enum Timeframe: String, CaseIterable, Identifiable, Sendable {
    case hour = "1H"
    case day = "1D"
    case week = "1W"

    public var id: String { rawValue }

    /// Live ticks are only appended on the shortest window; on longer windows
    /// a 1-second tick is sub-pixel and would only churn the chart.
    public var supportsLiveAppend: Bool { self == .hour }
}
