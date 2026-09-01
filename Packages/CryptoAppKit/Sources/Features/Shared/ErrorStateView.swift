import DesignSystem
import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text("Something went wrong")
                .font(AppTypography.label(17, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Text(message)
                .font(AppTypography.label(14))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("Try Again")
                    .font(AppTypography.label(15, weight: .semibold))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Palette.accent))
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
