import Domain
import Foundation

private let priceLocale = Locale(identifier: "en_US_POSIX")

extension Decimal {
    init?(apiString: String) {
        guard let value = Decimal(string: apiString, locale: priceLocale) else { return nil }
        self = value
    }
}

struct CombinedStreamMessage: Decodable {
    let stream: String
    let data: MiniTickerPayload
}

struct MiniTickerPayload: Decodable {
    let eventTimeMilliseconds: Int
    let symbol: String
    let lastPrice: String

    enum CodingKeys: String, CodingKey {
        case eventTimeMilliseconds = "E"
        case symbol = "s"
        case lastPrice = "c"
    }

    func validatedTick() -> PriceTick? {
        guard
            !symbol.isEmpty,
            let price = Decimal(apiString: lastPrice),
            price > 0
        else { return nil }
        return PriceTick(
            symbol: AssetSymbol(symbol),
            price: price,
            timestamp: Date(timeIntervalSince1970: TimeInterval(eventTimeMilliseconds) / 1000)
        )
    }
}

struct Ticker24hPayload: Decodable {
    let symbol: String
    let lastPrice: String
    let priceChangePercent: String
    let highPrice: String
    let lowPrice: String
    let quoteVolume: String

    func validatedSnapshot() -> MarketSnapshot? {
        guard
            !symbol.isEmpty,
            let last = Decimal(apiString: lastPrice), last > 0,
            let change = Decimal(apiString: priceChangePercent),
            let high = Decimal(apiString: highPrice),
            let low = Decimal(apiString: lowPrice),
            let volume = Decimal(apiString: quoteVolume)
        else { return nil }
        return MarketSnapshot(
            symbol: AssetSymbol(symbol),
            lastPrice: last,
            changePercent24h: change,
            high24h: high,
            low24h: low,
            quoteVolume24h: volume
        )
    }
}

/// Binance returns klines as positional arrays, not keyed objects,
/// hence the manual unkeyed decoding.
struct KlinePayload: Decodable {
    let openTimeMilliseconds: Int
    let closePrice: String

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        openTimeMilliseconds = try container.decode(Int.self)
        _ = try container.decode(String.self)
        _ = try container.decode(String.self)
        _ = try container.decode(String.self)
        closePrice = try container.decode(String.self)
    }

    func validatedPoint() -> PricePoint? {
        guard let price = Decimal(apiString: closePrice), price > 0 else { return nil }
        return PricePoint(
            timestamp: Date(timeIntervalSince1970: TimeInterval(openTimeMilliseconds) / 1000),
            price: price
        )
    }
}
