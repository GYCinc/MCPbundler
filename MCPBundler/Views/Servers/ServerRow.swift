//
//  ServerRow.swift
//  MCP Bundler
//
//  Display row (Name cell) for a server in the project detail list.
//

import SwiftUI

struct ServerRow: View {
    var server: Server
    var folder: ProviderFolder?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Indentation for folders
            if folder != nil {
                Color.clear.frame(width: 16)
            }

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 32, height: 32)

                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconForegroundColor)
            }
            .shadow(color: iconShadowColor, radius: 2, y: 1)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(server.alias)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(server.isEffectivelyEnabled ? .primary : .secondary)

                    if let folder = folder, !folder.isEnabled {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .help("Disabled by folder")
                    }
                }

                HStack(spacing: 6) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if server.kind == .remote_http_sse && server.usesOAuthAuthorization {
                         // Small indicator in subtitle
                        OAuthStatusIndicator(status: server.oauthStatus)
                            .scaleEffect(0.85)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch server.kind {
        case .local_stdio: return "terminal.fill"
        case .remote_http_sse: return "cloud.fill"
        }
    }

    private var subtitle: String {
        switch server.kind {
        case .local_stdio:
            return "Local STDIO"
        case .remote_http_sse:
            if let urlStr = server.baseURL, let url = URL(string: urlStr), let host = url.host {
                return host
            }
            return "Remote HTTP/SSE"
        }
    }

    private var iconBackgroundColor: Color {
        server.isEffectivelyEnabled ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.1)
    }

    private var iconForegroundColor: Color {
        server.isEffectivelyEnabled ? Color.accentColor : Color.secondary
    }

    private var iconShadowColor: Color {
        server.isEffectivelyEnabled ? Color.accentColor.opacity(0.15) : Color.clear
    }
}
