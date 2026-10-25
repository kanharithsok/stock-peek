import Foundation

struct Quote: Codable, Equatable, Sendable {
    let symbol: String
    let shortName: String?
    let longName: String?
    let quoteType: String?
    let currency: String?
    let regularMarketPrice: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
    let marketState: String?
    let exchangeName: String?

    var displayName: String {
        (longName ?? shortName) ?? symbol
    }
}

struct QuoteResponse: Codable {
    let quoteResponse: QuoteResult
}

struct QuoteResult: Codable {
    let result: [Quote]
    let error: QuoteError?
}

struct QuoteError: Codable {
    let code: String
    let description: String?
}

struct SearchResponse: Codable {
    let quotes: [SearchResult]?
}

struct SearchResult: Codable, Equatable, Identifiable, Sendable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String?
    let exchange: String?
    let exchDisp: String?

    var id: String { symbol }

    var name: String {
        (longname ?? shortname) ?? symbol
    }
}

enum YahooError: Error, LocalizedError {
    case badStatus(Int)
    case noData
    case decoding(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            return "Yahoo returned HTTP \(code)"
        case .noData:
            return "No data returned"
        case .decoding(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Authentication failed"
        }
    }
}
