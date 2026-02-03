//
//  OAuthStatusIndicator.swift
//  MCP Bundler
//
//  Shared pill indicator describing a server's OAuth connection state.
//

import SwiftUI

struct OAuthStatusIndicator: View {
    var status: OAuthStatus

    private var labelText: String {
        switch status {
        case .authorized: return "Signed In"
        case .refreshing: return "Refreshing"
        case .unauthorized: return "Sign-in Required"
        case .error: return "Needs Attention"
        }
    }

    private var iconName: String {
        switch status {
        case .authorized: return "checkmark.circle.fill"
        case .refreshing: return "clock.arrow.circlepath"
        case .unauthorized: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var tintColor: Color {
        switch status {
        case .authorized: return .green
        case .refreshing: return .blue
        case .unauthorized: return .red
        case .error: return .red
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption.weight(.semibold))
            Text(labelText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tintColor.opacity(0.12))
        .foregroundStyle(tintColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(tintColor.opacity(0.25), lineWidth: 1)
        )
    }
}
