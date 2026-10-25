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
            if let quote = store.quotes[symbol] {
                QuoteRow(quote: quote) {
                    store.remove(symbol: symbol)
                }
            }
        }
    }
}

private struct QuoteRow: View {
    let quote: Quote
    let onRemove: () -> Void

    private var change: Double {
        quote.regularMarketChange ?? 0
    }

    private var changePercent: Double {
        quote.regularMarketChangePercent ?? 0
    }

    private var color: Color {
        change >= 0 ? .green : .red
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(quote.symbol)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                    if let marketState = quote.marketState, marketState != "REGULAR" {
                        Text(badge(for: marketState))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(quote.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(priceText)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(color)
                HStack(spacing: 3) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
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
                    .frame(width: 18, height: 18)
                    .background(.quaternary.opacity(0.5), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Remove \(quote.symbol)")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }

    private var priceText: String {
        guard let price = quote.regularMarketPrice else { return "--" }
        return price.formatted(.number.precision(.fractionLength(2)))
    }

    private var changeText: String {
        guard let change = quote.regularMarketChange,
              let percent = quote.regularMarketChangePercent else { return "--" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.formatted(.number.precision(.fractionLength(2))))  (\(sign)\(percent.formatted(.number.precision(.fractionLength(2))))%)"
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

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search stocks (e.g. AAPL)", text: $store.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .onChange(of: store.searchQuery) { _, newValue in
                        store.search(newValue)
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
                ForEach(store.searchResults) { result in
                    SearchResultRow(result: result, isAdded: store.watchlist.contains(result.symbol)) {
                        store.add(result)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SearchResultRow: View {
    let result: SearchResult
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(result.symbol)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .monospacedDigit()
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
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
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
            }
            Spacer()
            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Settings")
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshing)
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("Quit")
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
