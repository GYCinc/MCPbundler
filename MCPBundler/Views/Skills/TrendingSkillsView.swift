import SwiftUI
import SwiftData
import Observation

struct TrendingSkillsView: View {
    @State private var trendingService = TrendingSkillsService()
    var marketplaceService: SkillMarketplaceService
    @Environment(\.modelContext) private var modelContext
    @Query private var existingSources: [SkillMarketplaceSource]

    @State private var addError: String?
    @State private var isAdding: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Trending (Last 7 Days)")
                    .font(.headline)
                Spacer()
                if trendingService.isScanning {
                    ProgressView()
                        .controlSize(.small)
                }
                Button {
                    Task {
                        await trendingService.fetchTrendingRepos()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(trendingService.isScanning)
                .help("Refresh Trending")
            }
            .padding()
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif

            if let error = trendingService.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }

            List(trendingService.trendingRepos) { repo in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(repo.full_name)
                            .font(.body)
                            .fontWeight(.medium)
                            .textSelection(.enabled)

                        if let desc = repo.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption2)
                            Text("\(repo.stargazers_count)")
                                .font(.caption)
                                .monospacedDigit()
                        }

                        if isAlreadyAdded(repo) {
                            Text("Added")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Add") {
                                Task {
                                    await addRepo(repo)
                                }
                            }
                            .disabled(isAdding)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .overlay {
                if trendingService.trendingRepos.isEmpty && !trendingService.isScanning {
                    ContentUnavailableView("No Trending Repos", systemImage: "star.slash", description: Text("Try refreshing to see trending MCP servers."))
                }
            }
        }
        .task {
            if trendingService.trendingRepos.isEmpty {
                await trendingService.fetchTrendingRepos()
            }
        }
        .alert("Failed to Add", isPresented: Binding(get: { addError != nil }, set: { if !$0 { addError = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            if let addError {
                Text(addError)
            }
        }
    }

    private func isAlreadyAdded(_ repo: TrendingRepo) -> Bool {
        let normalized = repo.full_name.lowercased()
        return existingSources.contains { source in
            let sourceKey = "\(source.owner)/\(source.repo)".lowercased()
            return sourceKey == normalized
        }
    }

    private func addRepo(_ repo: TrendingRepo) async {
        isAdding = true
        defer { isAdding = false }

        do {
            if isAlreadyAdded(repo) { return }

            // Fetch and validate
            let result = try await marketplaceService.fetchMarketplaceSkills(owner: repo.owner.login,
                                                                             repo: repo.name,
                                                                             cachedManifestSHA: nil,
                                                                             cachedMarketplaceJSON: nil,
                                                                             cachedSkillNames: nil,
                                                                             cachedDefaultBranch: nil)

            let availableSkills = result.listing.document.plugins
            guard !availableSkills.isEmpty else {
                addError = "Repository '\(repo.full_name)' has no skills listed in SKILL.md."
                return
            }

            let source = SkillMarketplaceSource(owner: repo.owner.login,
                                                repo: repo.name,
                                                displayName: repo.name)

            if let update = result.cacheUpdate {
                source.updateMarketplaceCache(manifestSHA: update.manifestSHA,
                                              defaultBranch: update.defaultBranch,
                                              manifestJSON: update.manifestJSON,
                                              skillNames: update.skillNames)
            } else {
                source.cachedDefaultBranch = result.listing.defaultBranch
                source.cacheUpdatedAt = Date()
            }

            modelContext.insert(source)
            try modelContext.save()

        } catch {
            addError = "Error adding repo: \(error.localizedDescription)"
        }
    }
}
