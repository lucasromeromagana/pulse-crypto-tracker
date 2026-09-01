import DesignSystem
import Domain
import SwiftUI

struct HoldingRowView: View {
    let position: HoldingValuation
    let movement: PriceMovement

    private var asset: Asset? {
        AssetCatalog.asset(for: position.holding.symbol)
    }

    var body: some View {
        HStack(spacing: 12) {
            TokenBadge(
                code: asset?.code ?? "?",
                color: asset.map { Color(hex: $0.brandColorHex) } ?? Palette.textTertiary,
                size: 38
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(asset?.code ?? position.holding.symbol.rawValue)
                    .font(AppTypography.label(15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("\(position.holding.quantity.quantityFormatted) \(asset?.code ?? "")")
                    .font(AppTypography.label(12))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(position.marketValue?.usdPrice ?? "—")
                    .font(AppTypography.numeric(15))
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText(value: position.marketValue?.doubleValue ?? 0))
                    .animation(.snappy(duration: 0.3), value: position.marketValue)
                    .flash(on: position.marketValue ?? 0, color: flashColor)
                returnLabel
            }
        }
        .card(padding: 14)
    }

    private var flashColor: Color {
        switch movement {
        case .up: Palette.gain
        case .down: Palette.loss
        case .flat: .clear
        }
    }

    @ViewBuilder
    private var returnLabel: some View {
        if let absolute = position.absoluteReturn, let relative = position.relativeReturn {
            Text("\(absolute.signedUSD) (\(relativeText(relative)))")
                .font(AppTypography.numeric(12))
                .foregroundStyle(absolute >= 0 ? Palette.gain : Palette.loss)
        } else if let price = position.currentPrice {
            Text("@ \(price.usdPrice)")
                .font(AppTypography.numeric(12))
                .foregroundStyle(Palette.textTertiary)
        } else {
            Text("Pricing…")
                .font(AppTypography.label(12))
                .foregroundStyle(Palette.textTertiary)
        }
    }

    private func relativeText(_ relative: Decimal) -> String {
        let sign = relative >= 0 ? "+" : "-"
        let percent = (relative.magnitude * 100).formatted(.number.precision(.fractionLength(1)))
        return "\(sign)\(percent)%"
    }
}
