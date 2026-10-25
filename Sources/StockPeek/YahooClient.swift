import Foundation

actor YahooClient {
    static let shared = YahooClient()

    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

    private let session: URLSession
    private var crumb: String?
    private let base = "https://query1.finance.yahoo.com"

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .always
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
        session = URLSession(configuration: config)
    }

    func quotes(symbols: [String]) async throws -> [Quote] {
        guard !symbols.isEmpty else { return [] }
        let joined = symbols.joined(separator: ",")
        let data = try await get(path: "/v7/finance/quote?symbols=\(joined)")
        let response = try JSONDecoder().decode(QuoteResponse.self, from: data)
        return response.quoteResponse.result
    }

    func search(query: String) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let data = try await get(path: "/v1/finance/search?q=\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)&quotesCount=12")
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.quotes ?? []
    }

    private func get(path: String) async throws -> Data {
        do {
            return try await perform(path: path)
        } catch YahooError.unauthorized {
            await refreshAuth()
            return try await perform(path: path)
        }
    }

    private func perform(path: String) async throws -> Data {
        let crumb = try await currentCrumb()
        guard let url = URL(string: "\(base)\(path)&crumb=\(crumb)") else {
            throw YahooError.noData
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200:
            return data
        case 401:
            throw YahooError.unauthorized
        default:
            throw YahooError.badStatus(status)
        }
    }

    private func currentCrumb() async throws -> String {
        if let crumb { return crumb }
        await refreshAuth()
        guard let crumb else { throw YahooError.unauthorized }
        return crumb
    }

    private func refreshAuth() async {
        crumb = nil
        _ = try? await session.data(from: URL(string: "https://fc.yahoo.com")!)
        var request = URLRequest(url: URL(string: "\(base)/v1/test/getcrumb")!)
        request.timeoutInterval = 15
        if let (data, response) = try? await session.data(for: request),
           let status = (response as? HTTPURLResponse)?.statusCode,
           status == 200,
           let value = String(data: data, encoding: .utf8),
           !value.isEmpty {
            crumb = value
        }
    }
}
