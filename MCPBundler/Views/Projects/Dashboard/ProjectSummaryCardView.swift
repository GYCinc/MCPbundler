//
//  ProjectSummaryCardView.swift
//  MCP Bundler
//
//  Displays project title, status, description, and key statistics.
//

import SwiftUI

struct ProjectSummaryCardView: View {
    @Bindable var project: Project
    var onSetActive: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 24) {
            // Left: Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(project.name)
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(.white)

                    if project.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.softGreen.opacity(0.1))
                            .foregroundColor(.softGreen)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.softGreen.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        Button(action: onSetActive) {
                            Text("SET ACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.05))
                                .foregroundColor(.textMuted)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(project.details ?? "Manage your Model Context Protocol servers. This environment is live and connected to local LLM clients.")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 600, alignment: .leading)
            }

            Spacer()

            // Right: Stats
            HStack(spacing: 12) {
                StatCard(label: "SERVERS", value: "\(project.servers.count)")
                StatCard(label: "TOOLS", value: "\(totalToolsCount)", valueColor: .primaryAccent)
                StatCard(label: "UPTIME", value: "99%", valueColor: .softGreen)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }

    private var totalToolsCount: Int {
        project.servers.reduce(0) { count, server in
            count + (server.latestDecodedCapabilities?.tools.count ?? 0)
        }
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textMuted)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(valueColor)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
