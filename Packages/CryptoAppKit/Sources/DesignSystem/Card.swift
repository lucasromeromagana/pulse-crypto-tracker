import SwiftUI

private struct CardStyle: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Palette.surface)
                    .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
            )
    }
}

public extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
