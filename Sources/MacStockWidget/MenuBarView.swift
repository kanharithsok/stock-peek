import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            if store.watchlist.isEmpty {
                EmptyStateView()
            } else {
                QuoteListView(store: store)
            }
            Divider()
            SearchSection(store: store)
            Divider()
            StatusFooter(store: store)
        }
        .frame(width: 340)
        .padding(8)
        .onChange(of: store.watchlist.count) {
            MacStockWidgetApp.fitPanelToContent()
        }
        .onDisappear {
            store.clearSearch()
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No stocks tracked")
                .font(.callout)
            Text("Search for a symbol below to add it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct QuoteListView: View {
    @ObservedObject var store: Store

    private static let estimatedRowHeight: CGFloat = 46

    private var screenHeight: CGFloat {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        return screen?.visibleFrame.height ?? 900
    }

    private var maxListHeight: CGFloat {
        min(max(screenHeight * 0.75, 240), 1400)
    }

    private var contentFits: Bool {
        let count = CGFloat(store.watchlist.count)
        return count * Self.estimatedRowHeight + (count - 1) * 2 <= maxListHeight
    }

    var body: some View {
        Group {
            if contentFits {
                VStack(spacing: 2) {
                    quoteRows
                }
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        quoteRows
                    }
                }
                .frame(height: maxListHeight)
            }
        }
    }

    private var quoteRows: some View {
        ForEach(store.watchlist, id: \.self) { symbol in
            QuoteRow(
                symbol: symbol,
                quote: store.quotes[symbol],
                isLoading: store.isRefreshing
            ) {
                store.remove(symbol: symbol)
            }
        }
    }
}

private struct QuoteRow: View {
    let symbol: String
    let quote: Quote?
    let isLoading: Bool
    let onRemove: () -> Void

    @State private var isHovering = false

    private var change: Double? {
        quote?.regularMarketChange
    }

    private var changePercent: Double? {
        quote?.regularMarketChangePercent
    }

    private var color: Color {
        guard let change, change != 0 else { return .secondary }
        return change > 0 ? .green : .red
    }

    private var directionSymbol: String {
        guard let change, change != 0 else { return "minus" }
        return change > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private var displayName: String {
        if let quote {
            return quote.displayName
        }
        return isLoading ? "Loading…" : "No quote data"
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(symbol)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                    if let marketState = quote?.marketState, marketState != "REGULAR" {
                        Text(badge(for: marketState))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 1) {
                Text(priceText)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(color)
                HStack(spacing: 3) {
                    Image(systemName: directionSymbol)
                        .font(.caption2)
                    Text(changeText)
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundStyle(color)
            }
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(.quaternary.opacity(0.5), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Remove \(symbol)")
            .accessibilityLabel("Remove \(symbol)")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.08) : .clear)
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .help(quote?.displayName ?? symbol)
        .contextMenu {
            if let url = yahooURL(for: symbol) {
                Button("Open in Yahoo Finance") {
                    NSWorkspace.shared.open(url)
                }
                Divider()
            }
            Button("Remove \(symbol)", role: .destructive, action: onRemove)
        }
    }

    private var priceText: String {
        guard let quote, let price = quote.regularMarketPrice else { return "—" }
        if let currency = quote.currency, !currency.isEmpty {
            return price.formatted(.currency(code: currency).precision(.fractionLength(2)))
        }
        return price.formatted(.number.precision(.fractionLength(2)))
    }

    private var changeText: String {
        guard let change, let percent = changePercent else { return "—" }
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(change.formatted(.number.precision(.fractionLength(2))))  (\(sign)\(percent.formatted(.number.precision(.fractionLength(2))))%)"
    }

    private func yahooURL(for symbol: String) -> URL? {
        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: "https://finance.yahoo.com/quote/\(encoded)")
    }

    private func badge(for state: String) -> String {
        switch state {
        case "PRE": return "Pre"
        case "POST": return "Post"
        case "CLOSED": return "Closed"
        default: return state
        }
    }
}

private struct SearchSection: View {
    @ObservedObject var store: Store
    @FocusState private var isSearchFocused: Bool

    private var trimmedQuery: String {
        store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search stocks (e.g. AAPL)", text: $store.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($isSearchFocused)
                    .accessibilityLabel("Search stocks")
                    .onChange(of: store.searchQuery) { _, newValue in
                        store.search(newValue)
                    }
                    .onSubmit {
                        if let first = store.searchResults.first,
                           !store.watchlist.contains(first.symbol) {
                            store.add(first)
                        }
                    }
                if !store.searchQuery.isEmpty {
                    Button {
                        store.clearSearch()
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
                if store.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

            if !store.searchResults.isEmpty {
                if store.searchResults.count > 4 {
                    ScrollView {
                        resultRows
                    }
                    .frame(height: 176)
                    .scrollIndicators(.visible)
                } else {
                    resultRows
                }
            } else if !trimmedQuery.isEmpty && !store.isSearching {
                Text("No matching symbols")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 6)
    }

    private var resultRows: some View {
        VStack(spacing: 0) {
            ForEach(store.searchResults) { result in
                SearchResultRow(
                    result: result,
                    isAdded: store.watchlist.contains(result.symbol)
                ) {
                    store.add(result)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SearchResultRow: View {
    let result: SearchResult
    let isAdded: Bool
    let onAdd: () -> Void

    @State private var isHovering = false

    private var exchange: String? {
        let value = result.exchDisp ?? result.exchange
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(result.symbol)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                        if let exchange {
                            Text(exchange)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Text(result.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if isAdded {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.05) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
        .onHover { isHovering = $0 }
        .help(isAdded ? "\(result.symbol) is already in your watchlist" : "Add \(result.symbol)")
        .accessibilityLabel("\(result.symbol), \(result.name)\(isAdded ? ", already added" : "")")
    }
}

private struct StatusFooter: View {
    @ObservedObject var store: Store
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 6) {
            if let error = store.errorMessage {
                Label {
                    Text("Update failed")
                        .lineLimit(1)
                        .help(error)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                .font(.caption)
            } else {
                Text(updatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                openSettings()
                MacStockWidgetApp.bringSettingsToFront()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")
            .accessibilityLabel("Settings")
            Button {
                Task { await store.refresh() }
            } label: {
                Group {
                    if store.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshing)
            .help("Refresh now")
            .accessibilityLabel("Refresh quotes")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit Stock Widget")
            .accessibilityLabel("Quit Stock Widget")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private var updatedText: String {
        guard let lastUpdated = store.lastUpdated else {
            return store.isRefreshing ? "Refreshing…" : "Never updated"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: lastUpdated))"
    }
}
