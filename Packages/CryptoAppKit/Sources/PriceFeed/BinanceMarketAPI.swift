import Domain
import Foundation

public struct BinanceMarketAPI: MarketDataProviding {
    private let baseURL: URL
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://api.binance.com")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func snapshots(for symbols: [AssetSymbol]) async throws -> [MarketSnapshot] {
        let symbolsJSON = "[" + symbols.map { "\"\($0.rawValue)\"" }.joined(separator: ",") + "]"
        let data = try await get(
            path: "/api/v3/ticker/24hr",
            queryItems: [URLQueryItem(name: "symbols", value: symbolsJSON)]
        )
        let payloads = try JSONDecoder().decode([Ticker24hPayload].self, from: data)
        let bySymbol = Dictionary(
            payloads.compactMap { $0.validatedSnapshot() }.map { ($0.symbol, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let ordered = symbols.compactMap { bySymbol[$0] }
        guard !ordered.isEmpty else { throw MarketDataError.emptyResponse }
        return ordered
    }

    public func history(for symbol: AssetSymbol, timeframe: Timeframe) async throws -> [PricePoint] {
        let (interval, limit) = Self.klineQuery(for: timeframe)
        let data = try await get(
            path: "/api/v3/klines",
            queryItems: [
                URLQueryItem(name: "symbol", value: symbol.rawValue),
                URLQueryItem(name: "interval", value: interval),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
        let points = try JSONDecoder()
            .decode([KlinePayload].self, from: data)
            .compactMap { $0.validatedPoint() }
        guard !points.isEmpty else { throw MarketDataError.emptyResponse }
        return points.sorted { $0.timestamp < $1.timestamp }
    }

    static func klineQuery(for timeframe: Timeframe) -> (interval: String, limit: Int) {
        switch timeframe {
        case .hour: ("1m", 60)
        case .day: ("15m", 96)
        case .week: ("1h", 168)
        }
    }

    private func get(path: String, queryItems: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MarketDataError.badStatus(http.statusCode)
        }
        return data
    }
}
