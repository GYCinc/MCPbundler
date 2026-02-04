//
//  ProjectDashboardView.swift
//  MCP Bundler
//
//  Main dashboard tab content for a project.
//

import SwiftUI
import SwiftData

struct ProjectDashboardView: View {
    @Bindable var project: Project
    @ObservedObject var importClientStore: ImportClientStore
    @Binding var activeImportClient: ImportClientDescriptor?
    @Binding var showingManualImport: Bool

    var onSetActive: () -> Void
    var onAddServer: () -> Void
    var onEditServer: (Server) -> Void
    var onDeleteServer: (Server) -> Void
    var onToggleServer: (Server, Bool) -> Void
    var executablePath: String

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ProjectSummaryCardView(project: project, onSetActive: onSetActive)

                ServerGridView(
                    project: project,
                    importClientStore: importClientStore,
                    activeImportClient: $activeImportClient,
                    showingManualImport: $showingManualImport,
                    onAddServer: onAddServer,
                    onEditServer: onEditServer,
                    onDeleteServer: onDeleteServer,
                    onToggleServer: onToggleServer
                )

                HeadlessConfigSectionView(
                    executablePath: executablePath,
                    clientCount: importClientStore.clients.count
                )
            }
            .padding(.bottom, 32)
        }
        .background(Color.bgDeep)
    }
}
