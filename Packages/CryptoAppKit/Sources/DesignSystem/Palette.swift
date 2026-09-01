import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #endif
    }
}

public enum Palette {
    public static let background = Color(light: Color(hex: 0xF4F5F9), dark: Color(hex: 0x0A0D14))
    public static let surface = Color(light: .white, dark: Color(hex: 0x121722))
    public static let surfaceElevated = Color(light: Color(hex: 0xFAFBFD), dark: Color(hex: 0x1A2130))
    public static let skeleton = Color(light: Color(hex: 0xE6E8EF), dark: Color(hex: 0x1E2534))

    public static let textPrimary = Color(light: Color(hex: 0x0D1220), dark: Color(hex: 0xF2F4F8))
    public static let textSecondary = Color(light: Color(hex: 0x5A6274), dark: Color(hex: 0x97A0B4))
    public static let textTertiary = Color(light: Color(hex: 0x8B92A5), dark: Color(hex: 0x5D6578))

    public static let gain = Color(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399))
    public static let loss = Color(light: Color(hex: 0xDC2F4E), dark: Color(hex: 0xF6465D))
    public static let accent = Color(light: Color(hex: 0x5857F0), dark: Color(hex: 0x7A9DFF))

    public static let strokeSubtle = Color(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.07)
    )

    public static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x5857F0), Color(hex: 0x7A5CF0), Color(hex: 0x9F58E8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
