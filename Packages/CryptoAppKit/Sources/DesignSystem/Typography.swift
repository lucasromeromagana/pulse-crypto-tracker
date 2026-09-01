import SwiftUI

/// Numbers use SF Rounded with monospaced digits: rounded reads "fintech",
/// and fixed-width digits stop live prices from jittering the layout every tick.
public enum AppTypography {
    public static func numeric(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        Font.system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    public static func label(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        Font.system(size: size, weight: weight)
    }
}
