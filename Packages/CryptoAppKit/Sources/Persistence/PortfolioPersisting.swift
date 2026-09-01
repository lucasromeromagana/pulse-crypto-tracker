import Domain
import Foundation

public protocol PortfolioPersisting: Sendable {
    func load() throws -> [Holding]
    func save(_ holdings: [Holding]) throws
}

/// Test/preview double. NSLock + @unchecked Sendable is deliberate: the protocol
/// is synchronous, and the lock provides the thread safety the compiler can't see.
public final class InMemoryPortfolioPersistence: PortfolioPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Holding]
    private var failNextSave: Error?

    public init(initial: [Holding] = []) {
        stored = initial
    }

    public func load() throws -> [Holding] {
        lock.withLock { stored }
    }

    public func save(_ holdings: [Holding]) throws {
        try lock.withLock {
            if let error = failNextSave {
                failNextSave = nil
                throw error
            }
            stored = holdings
        }
    }

    public func stub(nextSaveError: Error) {
        lock.withLock { failNextSave = nextSaveError }
    }
}
