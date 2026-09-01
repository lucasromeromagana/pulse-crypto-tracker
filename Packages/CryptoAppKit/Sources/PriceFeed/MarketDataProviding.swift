import Domain
import Foundation

public protocol MarketDataProviding: Sendable {
    func snapshots(for symbols: [AssetSymbol]) async throws -> [MarketSnapshot]
    func history(for symbol: AssetSymbol, timeframe: Timeframe) async throws -> [PricePoint]
}

public enum MarketDataError: Error, LocalizedError, Equatable {
    case badStatus(Int)
    case emptyResponse

    public var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            "The market data service responded with status \(code)."
        case .emptyResponse:
            "The market data service returned no usable data."
        }
    }
}
