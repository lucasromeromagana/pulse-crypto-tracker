import Domain

public enum FeedStatus: Hashable, Sendable {
    case connecting
    case live
    case reconnecting(attempt: Int)
}

public enum PriceFeedEvent: Hashable, Sendable {
    case status(FeedStatus)
    case tick(PriceTick)
}

/// The stream is deliberately non-throwing: reconnection is this layer's job,
/// so consumers only ever see ticks and connection status, never transport errors.
public protocol PriceStreaming: Sendable {
    func events(for symbols: [AssetSymbol]) -> AsyncStream<PriceFeedEvent>
}
