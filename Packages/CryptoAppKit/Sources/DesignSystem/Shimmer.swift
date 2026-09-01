import SwiftUI

private struct Shimmer: ViewModifier {
    @State private var isSweeping = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.6)
                    .offset(x: isSweeping ? width * 1.4 : -width * 0.9)
                }
                .animation(.linear(duration: 1.25).repeatForever(autoreverses: false), value: isSweeping)
            }
            .mask(content)
            .onAppear { isSweeping = true }
    }
}

public struct SkeletonBlock: View {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Palette.skeleton)
    }
}

public extension View {
    func shimmering() -> some View {
        modifier(Shimmer())
    }
}
