//
//  DashboardHeaderView.swift
//  MCP Bundler
//
//  Top navigation bar for the project dashboard.
//

import SwiftUI

enum DashboardTab: String, CaseIterable, Identifiable {
    case main
    case logs
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .main: return "Main"
        case .logs: return "Logs"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .main: return "square.grid.2x2"
        case .logs: return "terminal"
        case .settings: return "gearshape"
        }
    }
}

struct DashboardHeaderView: View {
    @Binding var selectedTab: DashboardTab

    var body: some View {
        HStack {
            // Navigation Tabs
            HStack(spacing: 8) {
                ForEach(DashboardTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedTab == tab ? Color.white.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .primaryAccent : .textMuted)
                        .cornerRadius(8)
                        .overlay(
                            Rectangle()
                                .fill(selectedTab == tab ? Color.primaryAccent : Color.clear)
                                .frame(height: 2)
                                .padding(.top, 30), // positioning at bottom
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // User/Help Area
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.textMuted)
                }
                .buttonStyle(.plain)

                HStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 24)

                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Dev User")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Admin")
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                        }

                        Circle()
                            .fill(Color.slate700)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.bgSidebar.opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.05)),
            alignment: .bottom
        )
    }
}
