//
//  SkillMarketplaceSourceDefaults.swift
//  MCP Bundler
//
//  Default marketplace sources and ordering rules.
//

import Foundation

struct SkillMarketplaceDefaultSource: Hashable {
    let owner: String
    let repo: String
    let displayName: String
    let sortRank: Int

    var normalizedKey: String {
        "\(owner)/\(repo)".lowercased()
    }
}

enum SkillMarketplaceSourceDefaults {
    static let sources: [SkillMarketplaceDefaultSource] = [
        SkillMarketplaceDefaultSource(owner: "eugenepyvovarov",
                                      repo: "mcpbundler-agent-skills-marketplace",
                                      displayName: "MCPBundler Currated Marketplace",
                                      sortRank: 0),
        SkillMarketplaceDefaultSource(owner: "ComposioHQ",
                                      repo: "awesome-claude-skills",
                                      displayName: "awesome-claude-skills",
                                      sortRank: 1),
        SkillMarketplaceDefaultSource(owner: "n8n-io",
                                      repo: "n8n",
                                      displayName: "n8n Workflow Automation",
                                      sortRank: 2),
        SkillMarketplaceDefaultSource(owner: "google-gemini",
                                      repo: "gemini-cli",
                                      displayName: "Gemini CLI",
                                      sortRank: 3),
        SkillMarketplaceDefaultSource(owner: "sansan0",
                                      repo: "TrendRadar",
                                      displayName: "TrendRadar",
                                      sortRank: 4),
        SkillMarketplaceDefaultSource(owner: "upstash",
                                      repo: "context7",
                                      displayName: "Context7",
                                      sortRank: 5),
        SkillMarketplaceDefaultSource(owner: "github",
                                      repo: "github-mcp-server",
                                      displayName: "GitHub MCP Server",
                                      sortRank: 6),
        SkillMarketplaceDefaultSource(owner: "bytedance",
                                      repo: "UI-TARS-desktop",
                                      displayName: "UI-TARS Desktop",
                                      sortRank: 7),
        SkillMarketplaceDefaultSource(owner: "assafelovic",
                                      repo: "gpt-researcher",
                                      displayName: "GPT Researcher",
                                      sortRank: 8),
        SkillMarketplaceDefaultSource(owner: "ChromeDevTools",
                                      repo: "chrome-devtools-mcp",
                                      displayName: "Chrome DevTools",
                                      sortRank: 9),
        SkillMarketplaceDefaultSource(owner: "activepieces",
                                      repo: "activepieces",
                                      displayName: "Activepieces",
                                      sortRank: 10),
        SkillMarketplaceDefaultSource(owner: "1Panel-dev",
                                      repo: "MaxKB",
                                      displayName: "MaxKB",
                                      sortRank: 11),
        SkillMarketplaceDefaultSource(owner: "oraios",
                                      repo: "serena",
                                      displayName: "Serena",
                                      sortRank: 12),
        SkillMarketplaceDefaultSource(owner: "microsoft",
                                      repo: "mcp-for-beginners",
                                      displayName: "MCP for Beginners",
                                      sortRank: 13),
        SkillMarketplaceDefaultSource(owner: "ruvnet",
                                      repo: "claude-flow",
                                      displayName: "Claude Flow",
                                      sortRank: 14),
        SkillMarketplaceDefaultSource(owner: "triggerdotdev",
                                      repo: "trigger.dev",
                                      displayName: "Trigger.dev",
                                      sortRank: 15),
        SkillMarketplaceDefaultSource(owner: "czlonkowski",
                                      repo: "n8n-mcp",
                                      displayName: "n8n MCP",
                                      sortRank: 16),
        SkillMarketplaceDefaultSource(owner: "tadata-org",
                                      repo: "fastapi_mcp",
                                      displayName: "FastAPI MCP",
                                      sortRank: 17),
        SkillMarketplaceDefaultSource(owner: "0xJacky",
                                      repo: "nginx-ui",
                                      displayName: "Nginx UI",
                                      sortRank: 18),
        SkillMarketplaceDefaultSource(owner: "JoeanAmier",
                                      repo: "XHS-Downloader",
                                      displayName: "XHS Downloader",
                                      sortRank: 19),
        SkillMarketplaceDefaultSource(owner: "mcp-use",
                                      repo: "mcp-use",
                                      displayName: "mcp-use",
                                      sortRank: 20),
        SkillMarketplaceDefaultSource(owner: "yusufkaraaslan",
                                      repo: "Skill_Seekers",
                                      displayName: "Skill Seekers",
                                      sortRank: 21)
    ]

    private static let sortOrder: [String: Int] = {
        var order: [String: Int] = [:]
        for source in sources {
            order[source.normalizedKey] = source.sortRank
        }
        return order
    }()

    static func sortRank(for normalizedKey: String) -> Int? {
        sortOrder[normalizedKey]
    }

    static func sortSources(_ sources: [SkillMarketplaceSource]) -> [SkillMarketplaceSource] {
        sources.sorted { lhs, rhs in
            let lhsRank = sortOrder[lhs.normalizedKey] ?? Int.max
            let rhsRank = sortOrder[rhs.normalizedKey] ?? Int.max
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            let nameOrder = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            let ownerOrder = lhs.owner.localizedCaseInsensitiveCompare(rhs.owner)
            if ownerOrder != .orderedSame {
                return ownerOrder == .orderedAscending
            }
            return lhs.repo.localizedCaseInsensitiveCompare(rhs.repo) == .orderedAscending
        }
    }
}
