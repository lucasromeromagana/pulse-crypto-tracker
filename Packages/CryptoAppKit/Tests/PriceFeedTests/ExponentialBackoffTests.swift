import Foundation
@testable import PriceFeed
import Testing

@Suite("Reconnection backoff policy")
struct ExponentialBackoffTests {
    @Test("Delays never exceed the exponential ceiling for their attempt")
    func respectsCeiling() {
        let backoff = ExponentialBackoff(initial: 0.5, multiplier: 2, cap: 30)
        var generator = SeededRandomGenerator(seed: 42)
        for attempt in 1...10 {
            let ceiling = min(30, 0.5 * pow(2, Double(attempt - 1)))
            let delay = backoff.delay(forAttempt: attempt, using: &generator)
            #expect(delay >= 0)
            #expect(delay <= ceiling)
        }
    }

    @Test("The ceiling is capped no matter how many attempts have failed")
    func capsAtMaximum() {
        let backoff = ExponentialBackoff(initial: 0.5, multiplier: 2, cap: 30)
        var generator = SeededRandomGenerator(seed: 7)
        let delay = backoff.delay(forAttempt: 50, using: &generator)
        #expect(delay <= 30)
    }

    @Test("The jittered sequence is deterministic for a fixed seed")
    func deterministicUnderSeed() {
        let backoff = ExponentialBackoff(initial: 0.5, multiplier: 2, cap: 30)
        var first = SeededRandomGenerator(seed: 99)
        var second = SeededRandomGenerator(seed: 99)
        let sequenceA = (1...8).map { backoff.delay(forAttempt: $0, using: &first) }
        let sequenceB = (1...8).map { backoff.delay(forAttempt: $0, using: &second) }
        #expect(sequenceA == sequenceB)
    }

    @Test("Jitter actually varies the delays across attempts")
    func jitterVaries() {
        let backoff = ExponentialBackoff(initial: 10, multiplier: 1, cap: 10)
        var generator = SeededRandomGenerator(seed: 1)
        let delays = Set((1...20).map { backoff.delay(forAttempt: $0, using: &generator) })
        #expect(delays.count > 1)
    }
}
