//
//  HealthBadge.swift
//  MCP Bundler
//
//  Displays a color-coded pill for server health status.
//

import SwiftUI

struct HealthBadge: View {
    var status: HealthStatus
    var customLabel: String? = nil
    var customIcon: String? = nil
    var customColor: Color? = nil

    private var labelText: String {
        if let customLabel, !customLabel.isEmpty { return customLabel }
        switch status {
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .unhealthy: return "Unhealthy"
        case .unknown: return "Unknown"
        }
    }

    private var iconName: String {
        if let customIcon { return customIcon }
        switch status {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    private var tintColor: Color {
        if let customColor { return customColor }
        switch status {
        case .healthy: return .green
        case .degraded: return .orange
        case .unhealthy: return .red
        case .unknown: return .secondary
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
