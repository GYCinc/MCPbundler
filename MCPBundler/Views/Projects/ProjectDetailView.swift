//
//  ProjectDetailView.swift
//  MCP Bundler
//
//  Displays the primary project management surface, including
//  server lists, environment configuration, and headless controls.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

struct ProjectPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Create your first project").font(.title2)
            Text("Group your MCP servers and switch contexts.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProjectDetailView: View {
    private static let serverDragType = UTType(exportedAs: "xyz.maketry.mcpbundler.server-token")

    @Environment(\.modelContext) private var modelContext
    @Environment(\.stdiosessionController) private var stdiosessionController
    @EnvironmentObject private var toastCenter: ToastCenter
    @EnvironmentObject private var installLinkCoordinator: InstallLinkCoordinator
    @Query private var allProjects: [Project]
    @Query private var locations: [SkillSyncLocation]

    @StateObject private var importClientStore: ImportClientStore
    @State private var showingAddServer = false
    @State private var editingServer: Server?
    @State private var serverToDelete: Server?
    @State private var selectedTab: DashboardTab = .main
    @State private var activeImportClient: ImportClientDescriptor?
    @State private var showingManualImport = false
    @State private var highlightOpacities: [UUID: Double] = [:]
    @State private var highlightTasks: [UUID: Task<Void, Never>] = [:]
    @State private var installLinkPresentation: InstallLinkPresentation?
    @State private var folderEditorMode: FolderEditorMode?
    @State private var folderNameDraft: String = ""
    @State private var folderValidationError: String?
    @State private var folderToDelete: ProviderFolder?
    @State private var isUnfolderDropTargeted: Bool = false
    @State private var isDraggingServer: Bool = false
    @State private var isDraggingServerFromFolder: Bool = false
    @State private var dragCleanupTask: Task<Void, Never>?
    @State private var serversTableView: NSTableView?
    @State private var serversTableAutoScroller = TableAutoScroller()
    @State private var ignoredSkillRules: [NativeSkillsSyncIgnoreRule] = []

    private let importer = ExternalConfigImporter()
    var project: Project

    init(project: Project) {
        self.project = project
        _importClientStore = StateObject(wrappedValue: ImportClientStore(executablePath: ProjectDetailView.resolveExecutablePath()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardHeaderView(selectedTab: $selectedTab)

            Group {
                switch selectedTab {
                case .main:
                    ProjectDashboardView(
                        project: project,
                        importClientStore: importClientStore,
                        activeImportClient: $activeImportClient,
                        showingManualImport: $showingManualImport,
                        onSetActive: { setActive(project) },
                        onAddServer: { showingAddServer = true },
                        onEditServer: { server in editingServer = server },
                        onDeleteServer: { server in serverToDelete = server },
                        onToggleServer: toggleServer,
                        executablePath: ProjectDetailView.resolveExecutablePath()
                    )
                case .logs:
                    LogsView(project: project)
                case .settings:
                    settingsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.bgDeep)
        .sheet(isPresented: $showingAddServer) {
            AddServerSheet(project: project)
                .frame(minWidth: 640, minHeight: 560)
        }
        .sheet(item: $editingServer) { server in
            ServerDetailSheet(server: server)
        }
        .sheet(item: $activeImportClient) { client in
            ImportServerPickerView(source: .client(client),
                                   importer: importer,
                                   project: project,
                                   onImported: handleImportResult,
                                   onReadFailure: handleImportFailure,
                                   onImportSummary: handleImportSummary)
        }
        .sheet(isPresented: $showingManualImport) {
            ImportJSONModalView(importer: importer,
                                project: project,
                                knownFormats: importClientStore.knownFormats,
                                onImported: handleImportResult,
                                onImportSummary: handleImportSummary)
        }
        .sheet(item: $installLinkPresentation) { presentation in
            ImportServerPickerView(source: .preloaded(description: presentation.description,
                                                      result: presentation.parseResult),
                                   importer: importer,
                                   project: project,
                                   onImported: handleImportResult,
                                   onReadFailure: handleImportFailure,
                                   onImportSummary: handleImportSummary)
        }
        .sheet(item: $folderEditorMode) { mode in
            NameEditSheet(title: mode.title,
                          placeholder: "Folder name",
                          name: $folderNameDraft,
                          validationError: $folderValidationError,
                          onSave: { name in
                              let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                              let validation = validateFolderName(trimmed, excluding: mode.folderReference)
                              if let validation {
                                  folderValidationError = validation
                                  return
                              }
                              switch mode {
                              case .create:
                                  createFolder(named: trimmed)
                              case .rename(let folder):
                                  renameFolder(folder, to: trimmed)
                              }
                              folderEditorMode = nil
                          },
                          onCancel: {
                              folderEditorMode = nil
                          })
        }
        .alert("Delete Server?", isPresented: Binding(
            get: { serverToDelete != nil },
            set: { if !$0 { serverToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let server = serverToDelete {
                    let event = makeEvent(for: server, type: .serverRemoved)
                    modelContext.delete(server)
                    saveContext(events: [event], rebuildSnapshots: true)
                }
                serverToDelete = nil
            }
            Button("Cancel", role: .cancel) { serverToDelete = nil }
        } message: {
            if let alias = serverToDelete?.alias {
                Text("Are you sure you want to delete \"\(alias)\"? This removes the server and its cached capabilities.")
            } else {
                Text("Are you sure you want to delete this server? This removes the server and its cached capabilities.")
            }
        }
        .alert("Delete Folder?", isPresented: Binding(
            get: { folderToDelete != nil },
            set: { if !$0 { folderToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete {
                    deleteFolder(folder)
                }
                folderToDelete = nil
            }
            Button("Cancel", role: .cancel) { folderToDelete = nil }
        } message: {
            if let name = folderToDelete?.name {
                Text("Delete folder \"\(name)\"? Servers will remain in the project as unfoldered.")
            } else {
                Text("Delete this folder? Servers will remain in the project as unfoldered.")
            }
        }
        .onReceive(installLinkCoordinator.$pendingPresentation) { _ in
            presentPendingInstallLinkIfNeeded()
        }
        .onAppear(perform: presentPendingInstallLinkIfNeeded)
    }

    // MARK: - Tab Views

    private var settingsTab: some View {
        List {
            SkillSyncLocationsView(displayStyle: .embedded)
            SkillMarketplaceSourcesView()

            if !ignoredSkillRules.isEmpty {
                skillsIgnoredSection
            }

            Section {
                settingsToggleRow(
                    icon: "eye.slash",
                    tint: .accentColor,
                    title: "Hide MCP tools under Search/Call Tools",
                    subtitle: "Show only search/call meta tools in the Tools menu while keeping full access via search.",
                    binding: contextOptimizationsBinding
                )
                settingsToggleRow(
                    icon: "wand.and.stars",
                    tint: .accentColor,
                    title: "Hide Skills for clients with native skills support (Claude, Codex)",
                    subtitle: "Hide Skills tools and resources for Claude Code and Codex MCP clients.",
                    binding: hideSkillsForNativeClientsBinding
                )
                settingsToggleRow(
                    icon: "text.document",
                    tint: .accentColor,
                    title: "Store large tool responses as files",
                    subtitle: "Writes oversized text replies to /tmp and returns a link instead of streaming everything inline.",
                    binding: largeResponseToggleBinding
                )
                if project.storeLargeToolResponsesAsFiles {
                    settingsThresholdRow
                }
            } header: {
                Text("Optimizations")
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .padding()
        .task {
            loadIgnoredSkillRules()
        }
    }

    private var skillsIgnoredSection: some View {
        Section {
            ForEach(ignoredSkillRules, id: \.self) { rule in
                settingsRow(
                    icon: ignoredToolIcon(for: rule.tool),
                    tint: .gray,
                    title: ignoredSkillTitle(for: rule),
                    subtitle: "\(ignoredToolTitle(for: rule.tool)): \(rule.directoryPath)"
                ) {
                    Button("Remove") {
                        let store = NativeSkillsSyncIgnoreStore()
                        store.removeIgnore(tool: rule.tool, directoryPath: rule.directoryPath)
                        loadIgnoredSkillRules()
                    }
                    .buttonStyle(.bordered)
                }
            }
        } header: {
            HStack {
                Text("Ignored Skills")
                Spacer()
                Button("Clear All") {
                    let store = NativeSkillsSyncIgnoreStore()
                    store.save([])
                    loadIgnoredSkillRules()
                }
                .buttonStyle(.borderless)
            }
        } footer: {
            Text("Ignored skills are hidden from the “Detected in …” list across all projects.")
        }
    }

    private func loadIgnoredSkillRules() {
        let store = NativeSkillsSyncIgnoreStore()
        ignoredSkillRules = store.load()
            .sorted { lhs, rhs in
                let toolOrder = lhs.tool.localizedCaseInsensitiveCompare(rhs.tool)
                if toolOrder != .orderedSame {
                    return toolOrder == .orderedAscending
                }
                return lhs.directoryPath.localizedCaseInsensitiveCompare(rhs.directoryPath) == .orderedAscending
        }
    }

    private func ignoredSkillTitle(for rule: NativeSkillsSyncIgnoreRule) -> String {
        let trimmed = rule.directoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Skill" }
        return URL(fileURLWithPath: trimmed).lastPathComponent
    }

    private func ignoredToolTitle(for tool: String) -> String {
        if let location = locations.first(where: { $0.locationId == tool }) {
            return location.displayName
        }
        switch tool.lowercased() {
        case "claude":
            return "Claude Code"
        case "codex":
            return "Codex"
        default:
            return tool
        }
    }

    private func ignoredToolIcon(for tool: String) -> String {
        switch tool.lowercased() {
        case "claude":
            return "c.square"
        case "codex":
            return "terminal"
        default:
            return "eye.slash"
        }
    }

    private func settingsToggleRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        binding: Binding<Bool>
    ) -> some View {
        settingsRow(
            icon: icon,
            tint: tint,
            title: title,
            subtitle: subtitle
        ) {
            Toggle("", isOn: binding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.regular)
        }
    }

    private var settingsThresholdRow: some View {
        settingsRow(
            icon: "gauge.with.dots.needle.100percent",
            tint: .accentColor,
            title: "Threshold",
            subtitle: "Characters before the response is written to disk."
        ) {
            HStack(spacing: 18) {
                Text(project.largeToolResponseThreshold.formatted())
                    .font(.title3.monospacedDigit())
                    .frame(minWidth: 70, alignment: .trailing)

                Stepper("", value: largeResponseThresholdBinding, in: 500...50000, step: 500)
                    .labelsHidden()
                    .controlSize(.regular)
            }
            .disabled(!project.storeLargeToolResponsesAsFiles)
        }
    }

    @ViewBuilder
    private func settingsRow<Content: View>(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.28),
                            tint.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                )
                .frame(width: 38, height: 38)
                .shadow(color: tint.opacity(0.25), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)
            trailing()
        }
        .padding(.vertical, 6)
    }

    private var contextOptimizationsBinding: Binding<Bool> {
        Binding(
            get: { project.contextOptimizationsEnabled },
            set: { newValue in
                guard project.contextOptimizationsEnabled != newValue else { return }
                project.contextOptimizationsEnabled = newValue
                saveContext()
            }
        )
    }

    private var hideSkillsForNativeClientsBinding: Binding<Bool> {
        Binding(
            get: { project.hideSkillsForNativeClients },
            set: { newValue in
                guard project.hideSkillsForNativeClients != newValue else { return }
                project.hideSkillsForNativeClients = newValue
                let event = makeSnapshotEvent(for: project)
                saveContext(events: [event], rebuildSnapshots: false)
            }
        )
    }

    private var largeResponseToggleBinding: Binding<Bool> {
        Binding(
            get: { project.storeLargeToolResponsesAsFiles },
            set: { newValue in
                guard project.storeLargeToolResponsesAsFiles != newValue else { return }
                project.storeLargeToolResponsesAsFiles = newValue
                let event = makeSnapshotEvent(for: project)
                saveContext(events: [event], rebuildSnapshots: false)
            }
        )
    }

    private var largeResponseThresholdBinding: Binding<Int> {
        Binding(
            get: { project.largeToolResponseThreshold },
            set: { newValue in
                let sanitized = max(0, newValue)
                guard project.largeToolResponseThreshold != sanitized else { return }
                project.largeToolResponseThreshold = sanitized
                let event = makeSnapshotEvent(for: project)
                saveContext(events: [event], rebuildSnapshots: false)
            }
        )
    }

    // MARK: - Supporting Types

    private enum FolderEditorMode: Identifiable {
        case create
        case rename(ProviderFolder)

        var id: String {
            switch self {
            case .create:
                return "create-folder"
            case .rename(let folder):
                return "rename-\(String(describing: folder.stableID))"
            }
        }

        var title: String {
            switch self {
            case .create: return "Add Folder"
            case .rename: return "Rename Folder"
            }
        }

        var folderReference: ProviderFolder? {
            switch self {
            case .create: return nil
            case .rename(let folder): return folder
            }
        }
    }

    private struct PendingEvent {
        let projectToken: UUID
        let type: BundlerEvent.EventType
        let serverTokens: [UUID]
    }

    // MARK: - Actions

    private func setActive(_ project: Project) {
        guard !project.isActive else { return }
        for candidate in allProjects {
            candidate.isActive = (candidate == project)
        }
        saveContext(rebuildSnapshots: true)
    }

    private func toggleServer(_ server: Server, _ isEnabled: Bool) {
        // If server is in a disabled folder, we might want to respect that or not.
        // The original logic checked folder status.
        if let folder = server.folder, !folder.isEnabled && isEnabled {
            // Cannot enable if folder is disabled? Original:
            // if folderDisabled && newValue { return }
            return
        }

        guard server.isEnabled != isEnabled else { return }
        server.isEnabled = isEnabled
        let event = makeEvent(for: server, type: isEnabled ? .serverEnabled : .serverDisabled)
        saveContext(events: [event], rebuildSnapshots: true)
    }

    private func addEnvVar(to project: Project) {
        let nextPosition = project.envVars.nextEnvPosition()
        let env = EnvVar(project: project,
                         key: "",
                         valueSource: .plain,
                         plainValue: "",
                         position: nextPosition)
        project.envVars.append(env)
        saveContext()
    }

    // MARK: - Data Management

    private func handleImportResult(_ result: ImportPersistenceResult) {
        highlight(result.server)
    }

    private func handleImportFailure(_ clientName: String) {
        toastCenter.push(text: "Unable to read config for \(clientName)", style: .warning)
    }

    private func handleImportSummary(_ successes: Int, _ failures: Int) {
        guard successes > 0 || failures > 0 else { return }
        var components: [String] = []
        if successes > 0 {
            let suffix = successes == 1 ? "" : "s"
            components.append("Imported \(successes) server\(suffix)")
        }
        if failures > 0 {
            components.append("\(failures) failed")
        }
        let message = components.joined(separator: "; ")
        toastCenter.push(text: message, style: failures > 0 ? .warning : .success)
    }

    private func highlight(_ server: Server) {
        let token = server.eventToken
        highlightTasks[token]?.cancel()
        highlightOpacities[token] = 0.5
        let task = Task { @MainActor in
            withAnimation(.easeOut(duration: 15)) {
                highlightOpacities[token] = 0.0
            }
            try? await Task.sleep(nanoseconds: UInt64(15 * 1_000_000_000))
            highlightOpacities.removeValue(forKey: token)
            highlightTasks.removeValue(forKey: token)
        }
        highlightTasks[token] = task
    }

    private func setFolderEnabled(_ folder: ProviderFolder, isEnabled: Bool) {
        guard folder.isEnabled != isEnabled else { return }
        folder.isEnabled = isEnabled
        folder.updatedAt = Date()
        for server in project.servers where server.folder?.stableID == folder.stableID {
            server.isEnabled = isEnabled
        }
        folder.project?.markUpdated()
        let event = makeSnapshotEvent(for: project)
        saveContext(events: [event], rebuildSnapshots: true)
    }

    private func toggleFolderCollapse(_ folder: ProviderFolder) {
        folder.isCollapsed.toggle()
        folder.updatedAt = Date()
        saveContext()
    }

    private func assign(_ server: Server, to folder: ProviderFolder?) {
        if let folder, server.folder?.stableID == folder.stableID { return }
        if folder == nil && server.folder == nil { return }
        server.folder = folder
        if let folder, folder.isEnabled == false {
            server.isEnabled = false
        }
        server.project?.markUpdated()
        let event = makeSnapshotEvent(for: project)
        saveContext(events: [event], rebuildSnapshots: true)
    }

    private func validateFolderName(_ raw: String, excluding existing: ProviderFolder? = nil) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Folder name cannot be empty." }
        let conflict = project.folders.contains { folder in
            guard folder !== existing else { return false }
            return folder.name.compare(trimmed, options: [.caseInsensitive]) == .orderedSame
        }
        if conflict { return "A folder with this name already exists in this project." }
        return nil
    }

    private func createFolder(named name: String) {
        guard validateFolderName(name) == nil else { return }
        let folder = ProviderFolder(project: project, name: name, isEnabled: true, isCollapsed: false)
        modelContext.insert(folder)
        if !project.folders.contains(where: { $0 === folder }) {
            project.folders.append(folder)
        }
        project.markUpdated()
        saveContext()
    }

    private func renameFolder(_ folder: ProviderFolder, to name: String) {
        if folder.name.compare(name, options: [.caseInsensitive]) == .orderedSame { return }
        guard validateFolderName(name, excluding: folder) == nil else { return }
        folder.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        folder.updatedAt = Date()
        folder.project?.markUpdated()
        saveContext()
    }

    private func deleteFolder(_ folder: ProviderFolder) {
        for server in project.servers where server.folder?.stableID == folder.stableID {
            server.folder = nil
        }
        project.folders.removeAll { $0.stableID == folder.stableID }
        modelContext.delete(folder)
        project.markUpdated()
        let event = makeSnapshotEvent(for: project)
        saveContext(events: [event], rebuildSnapshots: true)
    }

    private static func resolveExecutablePath() -> String {
        Bundle.main.executableURL?.path ?? "/Applications/MCPBundler.app/Contents/MacOS/MCPBundler"
    }

    private func presentPendingInstallLinkIfNeeded() {
        if let presentation = installLinkCoordinator.consumePresentation(matching: project.eventToken) {
            AppDelegate.writeToStderr("deeplink.detail.present project=\(project.name) desc=\(presentation.description)\n")
            installLinkPresentation = presentation
        }
    }

    private func makeEvent(for server: Server, type: BundlerEvent.EventType) -> PendingEvent {
        let projectToken = (server.project ?? project).eventToken
        return PendingEvent(projectToken: projectToken, type: type, serverTokens: [server.eventToken])
    }

    private func makeSnapshotEvent(for project: Project) -> PendingEvent {
        PendingEvent(projectToken: project.eventToken, type: .snapshotRebuilt, serverTokens: [])
    }

    private func saveContext(extraProjects: [Project] = [],
                             events: [PendingEvent] = [],
                             rebuildSnapshots: Bool = false) {
        do {
            try modelContext.save()
            guard rebuildSnapshots || !events.isEmpty else { return }
            let targets = [project] + extraProjects
            Task { @MainActor in
                var processed: Set<ObjectIdentifier> = []
                for candidate in targets {
                    let identifier = ObjectIdentifier(candidate)
                    if processed.insert(identifier).inserted {
                        if rebuildSnapshots {
                            try? await ProjectSnapshotCache.rebuildSnapshot(for: candidate)
                        }
                        let candidateToken = candidate.eventToken
                        let matching = events.filter { $0.projectToken == candidateToken }
                        var aggregatedTokens = Set<UUID>()
                        if matching.isEmpty {
                            // fall through and reload the entire project to keep preview in sync with snapshot
                        } else {
                            for event in matching {
                                aggregatedTokens.formUnion(event.serverTokens)
                                BundlerEventService.emit(in: modelContext,
                                                         projectToken: candidateToken,
                                                         serverTokens: event.serverTokens,
                                                         type: event.type)
                            }
                        }
                        let serverIDArray = candidate.servers
                            .filter { aggregatedTokens.contains($0.eventToken) }
                            .map { $0.persistentModelID }
                        let serverIDSet: Set<PersistentIdentifier>? = serverIDArray.isEmpty ? nil : Set(serverIDArray)
                        await stdiosessionController?.reload(projectID: candidate.persistentModelID,
                                                             serverIDs: serverIDSet)
                    }
                }
                if modelContext.hasChanges {
                    try? modelContext.save()
                }
            }
        } catch {
            assertionFailure("Failed to persist project changes: \(error)")
        }
    }
}
