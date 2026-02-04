import Foundation
import Observation

struct TrendingRepo: Identifiable, Decodable {
    let id: Int
    let name: String
    let full_name: String
    let description: String?
    let stargazers_count: Int
    let html_url: String
    let owner: TrendingRepoOwner
}

struct TrendingRepoOwner: Decodable {
    let login: String
    let avatar_url: String
}

struct TrendingResponse: Decodable {
    let items: [TrendingRepo]
}

@Observable
class TrendingSkillsService {
    var trendingRepos: [TrendingRepo] = []
    var isScanning: Bool = false
    var lastError: String?

    func fetchTrendingRepos(days: Int = 7) async {
        isScanning = true
        lastError = nil

        let date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)

        // Search for repos with topic 'mcp-server' created in the last 'days' days
        let queryString = "topic:mcp-server created:>\(dateString)"

        var components = URLComponents(string: "https://api.github.com/search/repositories")!
        components.queryItems = [
            URLQueryItem(name: "q", value: queryString),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "10")
        ]

        guard let url = components.url else {
            lastError = "Invalid URL construction"
            isScanning = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            // Use a User-Agent to avoid GitHub API limits/blocks
            request.setValue("MCPBundler-Trending/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Try to parse error message
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorJson["message"] as? String {
                     lastError = "GitHub API Error: \(message)"
                } else {
                     lastError = "GitHub API Error: \(httpResponse.statusCode)"
                }
                isScanning = false
                return
            }

            let result = try JSONDecoder().decode(TrendingResponse.self, from: data)
            self.trendingRepos = result.items
        } catch {
            lastError = "Failed to fetch: \(error.localizedDescription)"
        }

        isScanning = false
    }
}
