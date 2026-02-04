import urllib.request
import json
import ssl

def get_top_mcp_repos():
    url = "https://api.github.com/search/repositories?q=topic:mcp-server&sort=stars&order=desc&per_page=20"
    headers = {
        "User-Agent": "Python-Urllib",
        "Accept": "application/vnd.github.v3+json"
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        # Create unverified context to avoid SSL errors in some environments
        context = ssl._create_unverified_context()
        with urllib.request.urlopen(req, context=context) as response:
            data = json.loads(response.read().decode())
            return data.get("items", [])
    except Exception as e:
        print(f"Error: {e}")
        return []

repos = get_top_mcp_repos()
print(f"Found {len(repos)} repos")
for i, repo in enumerate(repos):
    owner = repo['owner']['login']
    name = repo['name']
    desc = repo.get('description', '') or 'No description'
    stars = repo['stargazers_count']
    print(f"{i}: {owner}/{name} - {desc} (Stars: {stars})")
