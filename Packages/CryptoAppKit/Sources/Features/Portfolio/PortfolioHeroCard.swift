import DesignSystem
import Domain
import SwiftUI

struct PortfolioHeroCard: View {
    let valuation: PortfolioValuation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Balance")
                .font(AppTypography.label(13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(valuation.totalValue.usdPrice)
                .font(AppTypography.numeric(36, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: valuation.totalValue.doubleValue))
                .animation(.snappy(duration: 0.35), value: valuation.totalValue)
            returnRow
            if !valuation.isFullyPriced {
                Text("Waiting for live prices on some holdings…")
                    .font(AppTypography.label(12))
                    .foregroundStyle(.white.opacity(0.65))
            }
            AllocationBar(segments: allocationSegments)
                .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Palette.heroGradient)
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 190, height: 190)
                        .offset(x: 130, y: -70)
                    Circle()
                        .fill(.white.opacity(0.05))
                        .frame(width: 120, height: 120)
                        .offset(x: -110, y: 60)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private var returnRow: some View {
        if let totalReturn = valuation.totalReturn,
           let relative = valuation.totalRelativeReturn {
            HStack(spacing: 8) {
                Text(totalReturn.signedUSD)
                    .font(AppTypography.numeric(15))
                    .contentTransition(.numericText())
                Text(relativeText(relative))
                    .font(AppTypography.numeric(13))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.18)))
            }
            .foregroundStyle(.white)
            .animation(.snappy(duration: 0.35), value: totalReturn)
        }
    }

    private func relativeText(_ relative: Decimal) -> String {
        let sign = relative >= 0 ? "+" : "-"
        let percent = (relative.magnitude * 100).formatted(.number.precision(.fractionLength(2)))
        return "\(sign)\(percent)%"
    }

    private var allocationSegments: [AllocationBar.Segment] {
        valuation.positions.compactMap { position in
            guard
                let weight = valuation.weight(of: position),
                let asset = AssetCatalog.asset(for: position.holding.symbol)
            else { return nil }
            return AllocationBar.Segment(
                id: position.id,
                color: Color(hex: asset.brandColorHex),
                fraction: weight.doubleValue
            )
        }
    }
}

struct AllocationBar: View {
    struct Segment: Identifiable {
        let id: UUID
        let color: Color
        let fraction: Double
    }

    let segments: [Segment]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    Capsule()
                        .fill(segment.color)
                        .frame(width: max(4, segment.fraction * geometry.size.width))
                }
            }
        }
        .frame(height: 7)
        .opacity(segments.isEmpty ? 0 : 1)
        .animation(.smooth(duration: 0.5), value: segments.map(\.fraction))
    }
}
