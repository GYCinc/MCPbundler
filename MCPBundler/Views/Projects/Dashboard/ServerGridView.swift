//
//  ServerGridView.swift
//  MCP Bundler
//
//  Grid of server cards with search and management actions.
//

import SwiftUI
import SwiftData

struct ServerGridView: View {
    @Bindable var project: Project
    @ObservedObject var importClientStore: ImportClientStore
    @Binding var activeImportClient: ImportClientDescriptor?
    @Binding var showingManualImport: Bool

    var onAddServer: () -> Void
    var onEditServer: (Server) -> Void
    var onDeleteServer: (Server) -> Void
    var onToggleServer: (Server, Bool) -> Void

    @State private var searchText = ""

    private var filteredServers: [Server] {
        let servers = project.sortedServers
        if searchText.isEmpty {
            return servers
        }
        return servers.filter { server in
            server.alias.localizedCaseInsensitiveContains(searchText) ||
            (server.baseURL?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (server.execPath?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Toolbar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .foregroundStyle(Color.primaryAccent)
                    Text("Servers")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textMuted)
                        TextField("Filter servers...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(width: 240)

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 20)

                    // Add Server
                    Button(action: onAddServer) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add Server")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.primaryAccent)
                        .foregroundColor(.bgDeep)
                        .cornerRadius(8)
                        .shadow(color: Color.primaryAccent.opacity(0.2), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    // Add Folder (Placeholder)
                    Button(action: {}) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 16))
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Add Folder (Coming soon)")

                    // Import Menu
                    Menu {
                        if importClientStore.clients.isEmpty {
                            Button("No importable configs found") {}
                                .disabled(true)
                        } else {
                            ForEach(importClientStore.clients) { client in
                                Button(client.displayName) {
                                    activeImportClient = client
                                }
                            }
                        }
                        Divider()
                        Button("Import JSON/TOML…") {
                            showingManualImport = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Import")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.05))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )

            // Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredServers) { server in
                    ServerCardView(
                        server: server,
                        onEdit: { onEditServer(server) },
                        onDelete: { onDeleteServer(server) },
                        onToggle: { onToggleServer(server, $0) }
                    )
                }
            }

            if filteredServers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.textMuted.opacity(0.5))
                    Text("No servers found")
                        .font(.headline)
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            }
        }
        .padding(.horizontal, 32)
    }
}
