//
//  ServerCardView.swift
//  MCP Bundler
//
//  Card view representing a single server in the dashboard grid.
//

import SwiftUI

struct ServerCardView: View {
    @Bindable var server: Server
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onToggle: (Bool) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )

                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(themeColor)
                    }
                    .shadow(color: themeColor.opacity(0.1), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.alias)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textMuted)
                            .fontDesign(.monospaced)
                    }
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { server.isEnabled },
                    set: { onToggle($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)
            }
            .padding(16)

            Spacer()

            // Footer
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    // Tools count
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill") // construction -> hammer
                            .font(.system(size: 10))
                        Text("\(totalTools)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(totalTools > 0 ? .white : .textMuted)

                    // Active/Bolt count
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("\(activeToolsCount)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(activeToolsCount > 0 ? .softGreen : .textMuted)

                    if server.usesOAuthAuthorization {
                         Text("AUTH")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Hover Actions
                if isHovering {
                    HStack(spacing: 4) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .padding(6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.textMuted)

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .padding(6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red.opacity(0.8))
                    }
                    .transition(.opacity)
                } else {
                    // Status Badge
                    HStack(spacing: 4) {
                        Text(statusText)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.02))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.05)),
                alignment: .top
            )
        }
        .frame(height: 140)
        .cardStyle()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Helpers

    private var themeColor: Color {
        // Deterministic color based on alias
        let colors: [Color] = [.blue, .purple, .softBlue, .orange, .pink, .softGreen]
        let hash = abs(server.alias.hashValue)
        return colors[hash % colors.count]
    }

    private var iconName: String {
        switch server.kind {
        case .local_stdio: return "terminal.fill"
        case .remote_http_sse:
            if server.alias.lowercased().contains("database") { return "server.rack" }
            if server.alias.lowercased().contains("api") { return "network" }
            return "globe"
        }
    }

    private var subtitle: String {
        switch server.kind {
        case .local_stdio: return "Local STDIO"
        case .remote_http_sse: return "Remote HTTP"
        }
    }

    private var totalTools: Int {
        server.latestDecodedCapabilities?.tools.count ?? 0
    }

    private var activeToolsCount: Int {
        guard server.isEffectivelyEnabled else { return 0 }

        guard let capabilities = server.latestDecodedCapabilities else {
            return server.includeTools.isEmpty ? 0 : server.includeTools.count
        }

        guard !server.includeTools.isEmpty else {
            return capabilities.tools.count
        }

        let include = Set(server.includeTools)
        return capabilities.tools.reduce(into: 0) { count, tool in
            if include.contains(tool.name) {
                count += 1
            }
        }
    }

    private var statusText: String {
        if !server.isEnabled { return "Stopped" }
        switch server.lastHealth {
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .unhealthy: return "Unhealthy"
        case .unknown: return "Unknown"
        }
    }

    private var statusColor: Color {
        if !server.isEnabled { return .textMuted }
        switch server.lastHealth {
        case .healthy: return .softGreen
        case .degraded: return .secondaryAccent
        case .unhealthy: return .red
        case .unknown: return .textMuted
        }
    }
}
