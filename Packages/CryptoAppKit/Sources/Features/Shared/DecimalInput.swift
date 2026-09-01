import Foundation

enum DecimalInput {
    /// Accepts both "0.5" and "0,5" so European keyboards aren't punished,
    /// then parses with a fixed locale so the result is deterministic.
    static func parse(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        // Decimal(string:) accepts garbage suffixes ("1.2.3" parses as 1.2),
        // so the whole string is shape-checked before parsing.
        guard
            normalized.wholeMatch(of: /-?\d+(?:\.\d+)?|-?\.\d+/) != nil,
            let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
            !value.isNaN
        else { return nil }
        return value
    }

    static func parsePositive(_ text: String) -> Decimal? {
        guard let value = parse(text), value > 0 else { return nil }
        return value
    }
}
