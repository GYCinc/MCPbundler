repos = [
    ("n8n-io", "n8n", "n8n Workflow Automation"),
    ("google-gemini", "gemini-cli", "Gemini CLI"),
    ("sansan0", "TrendRadar", "TrendRadar"),
    ("upstash", "context7", "Context7"),
    ("github", "github-mcp-server", "GitHub MCP Server"),
    ("bytedance", "UI-TARS-desktop", "UI-TARS Desktop"),
    ("assafelovic", "gpt-researcher", "GPT Researcher"),
    ("ChromeDevTools", "chrome-devtools-mcp", "Chrome DevTools"),
    ("activepieces", "activepieces", "Activepieces"),
    ("1Panel-dev", "MaxKB", "MaxKB"),
    ("oraios", "serena", "Serena"),
    ("microsoft", "mcp-for-beginners", "MCP for Beginners"),
    ("ruvnet", "claude-flow", "Claude Flow"),
    ("triggerdotdev", "trigger.dev", "Trigger.dev"),
    ("czlonkowski", "n8n-mcp", "n8n MCP"),
    ("tadata-org", "fastapi_mcp", "FastAPI MCP"),
    ("0xJacky", "nginx-ui", "Nginx UI"),
    ("JoeanAmier", "XHS-Downloader", "XHS Downloader"),
    ("mcp-use", "mcp-use", "mcp-use"),
    ("yusufkaraaslan", "Skill_Seekers", "Skill Seekers")
]

start_rank = 2
for i, (owner, repo, name) in enumerate(repos):
    print(f'        SkillMarketplaceDefaultSource(owner: "{owner}",')
    print(f'                                      repo: "{repo}",')
    print(f'                                      displayName: "{name}",')
    print(f'                                      sortRank: {start_rank + i}),')
