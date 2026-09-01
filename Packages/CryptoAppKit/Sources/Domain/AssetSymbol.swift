public struct AssetSymbol: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public var description: String { rawValue }
}
