import Domain
import Foundation
import Persistence
import Testing

@Suite("Portfolio persistence")
struct PortfolioStoreTests {
    private let btc = AssetSymbol("BTCUSDT")

    @Test("Holdings round-trip through the JSON file")
    func fileRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let persistence = FilePortfolioPersistence(directory: directory)
        // Whole-second dates: the .iso8601 strategy drops fractional seconds,
        // so Date() would round-trip unequal.
        let holdings = [
            Holding(
                symbol: btc,
                quantity: Decimal(string: "0.5")!,
                averageBuyPrice: 58_000,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            Holding(
                symbol: AssetSymbol("ETHUSDT"),
                quantity: 4,
                createdAt: Date(timeIntervalSince1970: 1_700_000_100)
            ),
        ]
        try persistence.save(holdings)
        #expect(try persistence.load() == holdings)
    }

    @Test("A corrupt file surfaces as a decoding error, and the store degrades to empty")
    func corruptFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{ not valid json".utf8)
            .write(to: directory.appendingPathComponent("holdings.json"))

        let persistence = FilePortfolioPersistence(directory: directory)
        #expect(throws: (any Error).self) { try persistence.load() }

        let store = PortfolioStore(persistence: persistence)
        #expect(await store.holdings().isEmpty)
    }

    @Test("Upsert inserts new holdings and replaces by identity")
    func upsertSemantics() async throws {
        let store = PortfolioStore(persistence: InMemoryPortfolioPersistence())
        var holding = Holding(symbol: btc, quantity: 1)
        try await store.upsert(holding)
        holding.quantity = 2
        try await store.upsert(holding)

        let holdings = await store.holdings()
        #expect(holdings.count == 1)
        #expect(holdings[0].quantity == 2)
    }

    @Test("A failed save rolls the in-memory state back and rethrows")
    func failedSaveRollsBack() async throws {
        let persistence = InMemoryPortfolioPersistence()
        let store = PortfolioStore(persistence: persistence)
        try await store.upsert(Holding(symbol: btc, quantity: 1))

        persistence.stub(nextSaveError: CocoaError(.fileWriteNoPermission))
        await #expect(throws: (any Error).self) {
            try await store.upsert(Holding(symbol: btc, quantity: 5))
        }
        let holdings = await store.holdings()
        #expect(holdings.count == 1)
        #expect(holdings[0].quantity == 1)
    }

    /// The concurrency-correctness test: 200 racing mutations must all land.
    /// Replace the actor with a class and this fails (or crashes) under TSan.
    @Test("Concurrent mutations are serialized without lost updates")
    func concurrentMutations() async throws {
        let store = PortfolioStore(persistence: InMemoryPortfolioPersistence())
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask {
                    try await store.upsert(
                        Holding(symbol: AssetSymbol("SYM\(index)"), quantity: Decimal(index + 1))
                    )
                }
            }
            try await group.waitForAll()
        }
        let holdings = await store.holdings()
        #expect(holdings.count == 200)
    }
}
