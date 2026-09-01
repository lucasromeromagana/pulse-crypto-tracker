import Foundation

extension Decimal {
    /// Adaptive precision: dollar-and-cents above $1, significant digits below,
    /// so DOGE at $0.1418 doesn't render as a useless "$0.14".
    var usdPrice: String {
        if self >= 1 {
            formatted(.currency(code: "USD").precision(.fractionLength(2)))
        } else {
            formatted(.currency(code: "USD").precision(.significantDigits(4)))
        }
    }

    // Hand-rolled compact notation: .notation(.compactName) on currency
    // styles requires iOS 18, and this app targets 17.
    var usdCompact: String {
        let value = doubleValue
        let (scaled, suffix): (Double, String) = switch value {
        case 1_000_000_000_000...: (value / 1_000_000_000_000, "T")
        case 1_000_000_000...: (value / 1_000_000_000, "B")
        case 1_000_000...: (value / 1_000_000, "M")
        case 1_000...: (value / 1_000, "K")
        default: (value, "")
        }
        return "$" + scaled.formatted(.number.precision(.fractionLength(0...1))) + suffix
    }

    var quantityFormatted: String {
        formatted(.number.precision(.fractionLength(0...8)))
    }

    var signedUSD: String {
        let body = magnitude.formatted(.currency(code: "USD").precision(.fractionLength(2)))
        return self < 0 ? "-\(body)" : "+\(body)"
    }

    var doubleValue: Double {
        (self as NSDecimalNumber).doubleValue
    }
}
