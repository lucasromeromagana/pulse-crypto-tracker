import Foundation

public struct ExponentialBackoff: Sendable {
    public var initial: TimeInterval
    public var multiplier: Double
    public var cap: TimeInterval

    public static let standard = ExponentialBackoff(initial: 0.5, multiplier: 2, cap: 30)

    public init(initial: TimeInterval, multiplier: Double, cap: TimeInterval) {
        self.initial = initial
        self.multiplier = multiplier
        self.cap = cap
    }

    /// Full jitter: a uniform draw from zero up to the exponential ceiling, so a
    /// fleet of clients dropped at the same moment doesn't reconnect in waves.
    public func delay(
        forAttempt attempt: Int,
        using generator: inout some RandomNumberGenerator
    ) -> TimeInterval {
        precondition(attempt >= 1, "Attempts are 1-based")
        let ceiling = min(cap, initial * pow(multiplier, Double(attempt - 1)))
        return TimeInterval.random(in: 0...ceiling, using: &generator)
    }
}

public struct SeededRandomGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
