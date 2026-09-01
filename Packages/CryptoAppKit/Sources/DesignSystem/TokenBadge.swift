import SwiftUI

public struct TokenBadge: View {
    private let code: String
    private let color: Color
    private let size: CGFloat

    public init(code: String, color: Color, size: CGFloat = 42) {
        self.code = code
        self.color = color
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.95), color.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.35), radius: size / 6, y: 2)
            Circle()
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            Text(code.prefix(1))
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
