public struct Asset: Identifiable, Hashable, Sendable {
    public let symbol: AssetSymbol
    public let code: String
    public let name: String
    public let brandColorHex: UInt32

    public var id: AssetSymbol { symbol }

    public init(symbol: AssetSymbol, code: String, name: String, brandColorHex: UInt32) {
        self.symbol = symbol
        self.code = code
        self.name = name
        self.brandColorHex = brandColorHex
    }
}

public enum AssetCatalog {
    public static let tracked: [Asset] = [
        Asset(symbol: AssetSymbol("BTCUSDT"), code: "BTC", name: "Bitcoin", brandColorHex: 0xF7931A),
        Asset(symbol: AssetSymbol("ETHUSDT"), code: "ETH", name: "Ethereum", brandColorHex: 0x627EEA),
        Asset(symbol: AssetSymbol("SOLUSDT"), code: "SOL", name: "Solana", brandColorHex: 0x9945FF),
        Asset(symbol: AssetSymbol("BNBUSDT"), code: "BNB", name: "BNB", brandColorHex: 0xF3BA2F),
        Asset(symbol: AssetSymbol("XRPUSDT"), code: "XRP", name: "XRP", brandColorHex: 0x0A85C7),
        Asset(symbol: AssetSymbol("ADAUSDT"), code: "ADA", name: "Cardano", brandColorHex: 0x2A6BD4),
        Asset(symbol: AssetSymbol("DOGEUSDT"), code: "DOGE", name: "Dogecoin", brandColorHex: 0xC2A633),
        Asset(symbol: AssetSymbol("AVAXUSDT"), code: "AVAX", name: "Avalanche", brandColorHex: 0xE84142),
        Asset(symbol: AssetSymbol("DOTUSDT"), code: "DOT", name: "Polkadot", brandColorHex: 0xE6007A),
        Asset(symbol: AssetSymbol("LINKUSDT"), code: "LINK", name: "Chainlink", brandColorHex: 0x2A5ADA),
        Asset(symbol: AssetSymbol("LTCUSDT"), code: "LTC", name: "Litecoin", brandColorHex: 0x647FBC),
        Asset(symbol: AssetSymbol("UNIUSDT"), code: "UNI", name: "Uniswap", brandColorHex: 0xFF007A),
    ]

    public static func asset(for symbol: AssetSymbol) -> Asset? {
        tracked.first { $0.symbol == symbol }
    }
}
