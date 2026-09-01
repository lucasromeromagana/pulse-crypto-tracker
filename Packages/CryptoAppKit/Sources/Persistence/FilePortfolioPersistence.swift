import Domain
import Foundation

public struct FilePortfolioPersistence: PortfolioPersisting {
    private let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appendingPathComponent("holdings.json")
    }

    public init() {
        let applicationSupport = URL.applicationSupportDirectory
            .appendingPathComponent("Portfolio", isDirectory: true)
        self.init(directory: applicationSupport)
    }

    public func load() throws -> [Holding] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Holding].self, from: data)
    }

    public func save(_ holdings: [Holding]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(holdings)
        try data.write(to: fileURL, options: .atomic)
    }
}
