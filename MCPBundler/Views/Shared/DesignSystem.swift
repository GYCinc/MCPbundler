//
//  DesignSystem.swift
//  MCP Bundler
//
//  Shared design tokens and styling helpers matching the Friendly Edition design.
//

import SwiftUI

extension Color {
    // --bg-deep: #0f172a
    static let bgDeep = Color(hex: 0x0f172a)
    // --bg-sidebar: #1e293b
    static let bgSidebar = Color(hex: 0x1e293b)
    // --bg-card: #14213d
    static let bgCard = Color(hex: 0x14213d)
    // --primary-accent: #fbbf24
    static let primaryAccent = Color(hex: 0xfbbf24)
    // --secondary-accent: #f59e0b
    static let secondaryAccent = Color(hex: 0xf59e0b)
    // --soft-green: #10b981
    static let softGreen = Color(hex: 0x10b981)
    // --soft-blue: #38bdf8
    static let softBlue = Color(hex: 0x38bdf8)
    // --text-main: #e2e8f0
    static let textMain = Color(hex: 0xe2e8f0)
    // --text-muted: #94a3b8
    static let textMuted = Color(hex: 0x94a3b8)

    // Additional colors inferred from design
    static let emerald400 = Color(hex: 0x34d399) // Approximate for text-emerald-400
    static let emerald500 = Color(hex: 0x10b981)
    static let slate700 = Color(hex: 0x334155)
    static let slate900 = Color(hex: 0x0f172a)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// Reusable styling modifiers
struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackgroundModifier())
    }
}
