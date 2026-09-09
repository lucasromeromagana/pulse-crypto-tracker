import Domain
import Foundation
import OSLog

public struct BinancePriceStream: PriceStreaming {
    public struct Configuration: Sendable {
        public var endpoint: URL
        public var backoff: ExponentialBackoff
        /// How long the receive loop tolerates silence before treating the
        /// connection as dead and reconnecting. Binance ticks at least once per
        /// second, so the default of 10 s is generous; injectable so tests and
        /// alternative endpoints can tune it, like `backoff` and its generator.
        public var silenceTimeout: TimeInterval

        public init(
            endpoint: URL = URL(string: "wss://stream.binance.com:9443/stream")!,
            backoff: ExponentialBackoff = .standard,
            silenceTimeout: TimeInterval = 10
        ) {
            self.endpoint = endpoint
            self.backoff = backoff
            self.silenceTimeout = silenceTimeout
        }
    }

    private static let logger = Logger(subsystem: "dev.lucasromero.cryptoapp", category: "PriceFeed")
    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    public func events(for symbols: [AssetSymbol]) -> AsyncStream<PriceFeedEvent> {
        let url = subscriptionURL(for: symbols)
        let backoff = configuration.backoff

        return AsyncStream(bufferingPolicy: .bufferingNewest(256)) { continuation in
            let connectionLoop = Task {
                var attempt = 0
                var generator = SystemRandomNumberGenerator()

                while !Task.isCancelled {
                    if attempt == 0 {
                        continuation.yield(.status(.connecting))
                    }
                    let socket = URLSession.shared.webSocketTask(with: url)
                    socket.resume()
                    do {
                        var awaitingFirstMessage = true
                        while !Task.isCancelled {
                            let message = try await Self.receiveWithTimeout(socket, seconds: configuration.silenceTimeout)
                            if awaitingFirstMessage {
                                awaitingFirstMessage = false
                                attempt = 0
                                continuation.yield(.status(.live))
                            }
                            if let tick = Self.tick(from: message) {
                                continuation.yield(.tick(tick))
                            }
                        }
                        socket.cancel(with: .goingAway, reason: nil)
                    } catch {
                        socket.cancel(with: .abnormalClosure, reason: nil)
                        guard !Task.isCancelled else { break }
                        attempt += 1
                        continuation.yield(.status(.reconnecting(attempt: attempt)))
                        Self.logger.warning("Socket dropped (attempt \(attempt)): \(error.localizedDescription)")
                        let delay = backoff.delay(forAttempt: attempt, using: &generator)
                        try? await Task.sleep(for: .seconds(delay))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in connectionLoop.cancel() }
        }
    }

    private func subscriptionURL(for symbols: [AssetSymbol]) -> URL {
        let streams = symbols
            .map { "\($0.rawValue.lowercased())@miniTicker" }
            .joined(separator: "/")
        var components = URLComponents(url: configuration.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "streams", value: streams)]
        return components.url!
    }

    /// Races `socket.receive()` against a silence timeout so a dead connection
    /// can't wedge the receive loop indefinitely.
    ///
    /// A TCP connection that dies silently — Wi-Fi cut mid-stream, the peer
    /// disappearing without sending a close frame — never surfaces an error to
    /// `receive()`; the call just suspends, sometimes for minutes, so the
    /// reconnection logic in the catch path never gets a chance to run. Binance
    /// publishes a miniTicker at least once per second, which makes a gap longer
    /// than `seconds` a reliable death signal rather than mere idleness. When the
    /// timeout wins the race we throw `URLError(.timedOut)`, turning the silence
    /// into an ordinary receive failure that flows into the existing backoff and
    /// reconnect path like any other transport error.
    private static func receiveWithTimeout(
        _ socket: URLSessionWebSocketTask,
        seconds: TimeInterval
    ) async throws -> URLSessionWebSocketTask.Message {
        try await withThrowingTaskGroup(of: URLSessionWebSocketTask.Message.self) { group in
            group.addTask {
                try await socket.receive()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw URLError(.timedOut)
            }
            // Whichever child finishes first wins; cancel the loser so we never
            // leak a dangling receive or an unfired timer.
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw URLError(.timedOut) }
            return first
        }
    }

    static func tick(from message: URLSessionWebSocketTask.Message) -> PriceTick? {
        let payload: Data
        switch message {
        case .string(let text):
            payload = Data(text.utf8)
        case .data(let data):
            payload = data
        @unknown default:
            return nil
        }
        return tick(fromJSON: payload)
    }

    /// A malformed or incomplete frame is dropped and logged — one bad message
    /// must never tear down the stream or surface a bogus price.
    static func tick(fromJSON payload: Data) -> PriceTick? {
        do {
            let message = try JSONDecoder().decode(CombinedStreamMessage.self, from: payload)
            guard let tick = message.data.validatedTick() else {
                logger.error("Dropped miniTicker frame that failed validation")
                return nil
            }
            return tick
        } catch {
            logger.error("Dropped undecodable frame: \(error.localizedDescription)")
            return nil
        }
    }
}
