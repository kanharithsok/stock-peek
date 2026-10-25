import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {
    @Published private(set) var quotes: [String: Quote] = [:]
    @Published private(set) var watchlist: [String] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    @Published var searchQuery = ""
    @Published private(set) var searchResults: [SearchResult] = []
    @Published private(set) var isSearching = false

    private var timer: Timer?
    private var searchTask: Task<Void, Never>?
    private var defaultsObserver: NSObjectProtocol?
    private let defaults = UserDefaults.standard
    private let client = YahooClient.shared
    private let watchlistKey = "watchlist"
    private let quotesKey = "cachedQuotes"

    @AppStorage("refreshInterval") private var refreshInterval: Double = 30

    init() {
        LegacyMigration.runIfNeeded()
        loadWatchlist()
        loadCachedQuotes()
        startTimer()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.restartTimer()
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        guard !watchlist.isEmpty, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fetched = try await client.quotes(symbols: watchlist)
            var merged = quotes
            for quote in fetched {
                merged[quote.symbol] = quote
            }
            quotes = merged
            lastUpdated = Date()
            errorMessage = nil
            persistQuotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(_ result: SearchResult) {
        guard !watchlist.contains(result.symbol) else {
            clearSearch()
            return
        }
        watchlist.append(result.symbol)
        persistWatchlist()
        clearSearch()
        Task { await refresh() }
    }

    func remove(symbol: String) {
        watchlist.removeAll { $0 == symbol }
        quotes[symbol] = nil
        persistWatchlist()
        persistQuotes()
    }

    func move(symbol: String, to target: String, after: Bool) {
        guard symbol != target,
              let from = watchlist.firstIndex(of: symbol),
              let targetIndex = watchlist.firstIndex(of: target) else { return }

        var updated = watchlist
        updated.remove(at: from)

        var insertionIndex = targetIndex
        if from < targetIndex {
            insertionIndex -= 1
        }
        if after {
            insertionIndex += 1
        }
        guard insertionIndex <= updated.endIndex else { return }

        updated.insert(symbol, at: insertionIndex)
        withAnimation(.easeInOut(duration: 0.18)) {
            watchlist = updated
        }
        persistWatchlist()
    }

    func move(symbol: String, by offset: Int) {
        guard let index = watchlist.firstIndex(of: symbol) else { return }
        let targetIndex = index + offset
        guard watchlist.indices.contains(targetIndex) else { return }

        var updated = watchlist
        updated.swapAt(index, targetIndex)
        withAnimation(.easeInOut(duration: 0.18)) {
            watchlist = updated
        }
        persistWatchlist()
    }

    func removeAll() {
        watchlist.removeAll()
        quotes.removeAll()
        persistWatchlist()
        persistQuotes()
    }

    func search(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        searchResults = []
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = (try? await client.search(query: trimmed)) ?? []
            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
        searchTask?.cancel()
    }

    private func startTimer() {
        let interval = max(refreshInterval, 10)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = nil
        startTimer()
    }

    private func loadWatchlist() {
        watchlist = defaults.stringArray(forKey: watchlistKey) ?? []
    }

    private func persistWatchlist() {
        defaults.set(watchlist, forKey: watchlistKey)
    }

    private func loadCachedQuotes() {
        guard let data = defaults.data(forKey: quotesKey),
              let cached = try? JSONDecoder().decode([String: Quote].self, from: data) else { return }
        quotes = cached
    }

    private func persistQuotes() {
        if let data = try? JSONEncoder().encode(quotes) {
            defaults.set(data, forKey: quotesKey)
        }
    }
}
