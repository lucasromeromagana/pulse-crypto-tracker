import DesignSystem
import Domain
import SwiftUI

struct TimeframePicker: View {
    let selection: Timeframe
    let onSelect: (Timeframe) -> Void
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Timeframe.allCases) { timeframe in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        onSelect(timeframe)
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(AppTypography.label(13, weight: .semibold))
                        .foregroundStyle(
                            timeframe == selection ? Palette.textPrimary : Palette.textSecondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if timeframe == selection {
                                Capsule()
                                    .fill(Palette.surfaceElevated)
                                    .overlay(Capsule().strokeBorder(Palette.strokeSubtle, lineWidth: 1))
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Palette.background))
    }
}
