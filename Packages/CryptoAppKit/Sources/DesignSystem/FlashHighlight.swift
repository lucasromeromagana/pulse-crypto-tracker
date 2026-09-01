import SwiftUI

private struct FlashHighlight<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let color: Color
    @State private var isFlashing = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(isFlashing ? 0.2 : 0))
                    .padding(-5)
            )
            .onChange(of: trigger) {
                withAnimation(.easeIn(duration: 0.1)) { isFlashing = true }
                withAnimation(.easeOut(duration: 0.65).delay(0.15)) { isFlashing = false }
            }
    }
}

public extension View {
    /// Briefly washes the view in `color` whenever `trigger` changes —
    /// the classic green/red pulse on a live price.
    func flash(on trigger: some Equatable, color: Color) -> some View {
        modifier(FlashHighlight(trigger: trigger, color: color))
    }
}
