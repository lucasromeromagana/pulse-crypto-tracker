import DesignSystem
import PriceFeed
import SwiftUI

struct FeedStatusBadge: View {
    let status: FeedStatus
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .opacity(isPulsing ? 0.35 : 1)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Text(label)
                .font(AppTypography.label(12, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.12)))
        .onAppear { isPulsing = true }
        .accessibilityLabel("Feed status: \(label)")
    }

    private var tint: Color {
        switch status {
        case .live: Palette.gain
        case .connecting: Color.orange
        case .reconnecting: Palette.loss
        }
    }

    private var label: String {
        switch status {
        case .live: "Live"
        case .connecting: "Connecting"
        case .reconnecting: "Reconnecting"
        }
    }
}
