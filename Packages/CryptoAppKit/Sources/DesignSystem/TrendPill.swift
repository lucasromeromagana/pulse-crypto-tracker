import Foundation
import SwiftUI

public struct TrendPill: View {
    private let changePercent: Decimal

    public init(changePercent: Decimal) {
        self.changePercent = changePercent
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbolName)
                .font(.system(size: 10, weight: .bold))
            Text(formattedPercent)
                .font(AppTypography.numeric(13))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.13)))
        .contentTransition(.numericText())
    }

    private var tint: Color {
        if changePercent > 0 { Palette.gain } else if changePercent < 0 { Palette.loss } else { Palette.textSecondary }
    }

    private var symbolName: String {
        if changePercent > 0 { "arrow.up.right" } else if changePercent < 0 { "arrow.down.right" } else { "minus" }
    }

    private var formattedPercent: String {
        let magnitude = changePercent.magnitude
        return magnitude.formatted(.number.precision(.fractionLength(2))) + "%"
    }
}
