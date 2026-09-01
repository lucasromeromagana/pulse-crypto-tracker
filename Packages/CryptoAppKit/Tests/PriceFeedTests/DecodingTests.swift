import Domain
import Foundation
@testable import PriceFeed
import Testing

@Suite("Defensive decoding of Binance frames")
struct DecodingTests {
    private func frame(price: String, symbol: String = "BTCUSDT") -> Data {
        Data("""
        {"stream":"btcusdt@miniTicker","data":{"e":"24hrMiniTicker","E":1700000000000,\
        "s":"\(symbol)","c":"\(price)","o":"66000.00","h":"68000.00","l":"65000.00",\
        "v":"20000.5","q":"1340000000.2"}}
        """.utf8)
    }

    @Test("A well-formed miniTicker frame decodes into a validated tick")
    func validFrame() throws {
        let tick = try #require(BinancePriceStream.tick(fromJSON: frame(price: "67241.30000000")))
        #expect(tick.symbol == AssetSymbol("BTCUSDT"))
        #expect(tick.price == Decimal(string: "67241.3")!)
        #expect(tick.timestamp == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test("Garbage bytes are dropped, not crashed on")
    func garbagePayload() {
        #expect(BinancePriceStream.tick(fromJSON: Data("not json at all".utf8)) == nil)
    }

    @Test("A frame missing required fields is dropped")
    func incompleteFrame() {
        let payload = Data(#"{"stream":"btcusdt@miniTicker","data":{"e":"24hrMiniTicker"}}"#.utf8)
        #expect(BinancePriceStream.tick(fromJSON: payload) == nil)
    }

    @Test("Non-numeric, zero, and negative prices are all rejected",
          arguments: ["abc", "0", "-1.5", ""])
    func invalidPrices(price: String) {
        #expect(BinancePriceStream.tick(fromJSON: frame(price: price)) == nil)
    }

    @Test("Kline rows decode positionally and keep only valid points")
    func klineDecoding() throws {
        let payload = Data("""
        [[1700000000000,"66000.1","66100.0","65900.0","66050.5","12.5",1700000059999,\
        "825631.2",100,"6.2","409390.9","0"],
        [1700000060000,"66050.5","66200.0","66000.0","bogus","11.1",1700000119999,\
        "733158.0",90,"5.5","363300.0","0"]]
        """.utf8)
        let points = try JSONDecoder()
            .decode([KlinePayload].self, from: payload)
            .compactMap { $0.validatedPoint() }
        #expect(points.count == 1)
        #expect(points[0].price == Decimal(string: "66050.5")!)
    }

    @Test("24h ticker rows survive individually invalid entries")
    func tickerValidation() throws {
        let payload = Data("""
        [{"symbol":"BTCUSDT","lastPrice":"67000.0","priceChangePercent":"2.35",\
        "highPrice":"68000","lowPrice":"65000","quoteVolume":"1340000000"},
        {"symbol":"ETHUSDT","lastPrice":"-5","priceChangePercent":"1.0",\
        "highPrice":"1","lowPrice":"1","quoteVolume":"1"}]
        """.utf8)
        let snapshots = try JSONDecoder()
            .decode([Ticker24hPayload].self, from: payload)
            .compactMap { $0.validatedSnapshot() }
        #expect(snapshots.count == 1)
        #expect(snapshots[0].symbol == AssetSymbol("BTCUSDT"))
        #expect(snapshots[0].changePercent24h == Decimal(string: "2.35")!)
    }
}
