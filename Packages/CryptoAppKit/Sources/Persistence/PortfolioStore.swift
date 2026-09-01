import Domain
import Foundation
import OSLog

/// Actor-isolated so every mutation is an atomic read-modify-write and disk
/// writes happen strictly in mutation order — concurrent edits can't lose an
/// update or interleave file writes.
public actor PortfolioStore {
    private static let logger = Logger(subsystem: "dev.lucasromero.cryptoapp", category: "Persistence")
    private let persistence: any PortfolioPersisting
    private var cache: [Holding]?

    public init(persistence: any PortfolioPersisting) {
        self.persistence = persistence
    }

    public func holdings() -> [Holding] {
        loadIfNeeded()
    }

    public func upsert(_ holding: Holding) throws {
        var updated = loadIfNeeded()
        if let index = updated.firstIndex(where: { $0.id == holding.id }) {
            updated[index] = holding
        } else {
            updated.append(holding)
        }
        try commit(updated)
    }

    public func remove(holdingID: UUID) throws {
        var updated = loadIfNeeded()
        updated.removeAll { $0.id == holdingID }
        try commit(updated)
    }

    /// Memory is updated first, then persisted; a failed write rolls memory
    /// back and rethrows so the UI never shows state that didn't stick.
    private func commit(_ holdings: [Holding]) throws {
        let previous = cache
        cache = holdings
        do {
            try persistence.save(holdings)
        } catch {
            cache = previous
            Self.logger.error("Portfolio save failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func loadIfNeeded() -> [Holding] {
        if let cache { return cache }
        do {
            let loaded = try persistence.load()
            cache = loaded
            return loaded
        } catch {
            Self.logger.error("Portfolio load failed, starting empty: \(error.localizedDescription)")
            cache = []
            return []
        }
    }
}
