import ServiceManagement
import SwiftUI

enum RefreshInterval: Double, CaseIterable, Identifiable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
    case oneEighty = 180
    case threeHundred = 300

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .fifteen: "15 seconds"
        case .thirty: "30 seconds"
        case .sixty: "1 minute"
        case .oneEighty: "3 minutes"
        case .threeHundred: "5 minutes"
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("refreshInterval") var refreshInterval: Double = RefreshInterval.thirty.rawValue
    @Published var isLaunchAtLogin: Bool
    @Published var launchAtLoginError: String?

    init() {
        isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = "Couldn’t update login item: \(error.localizedDescription)"
            NSLog("Failed to update login item: \(error)")
        }
        isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct SettingsView: View {
    @ObservedObject var store: Store
    @ObservedObject var settings: SettingsStore
    @State private var showRemoveAllConfirmation = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.isLaunchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker("Refresh interval", selection: $settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval.rawValue)
                    }
                }
            }
            Section("Watchlist") {
                Button("Remove all tracked stocks", role: .destructive) {
                    showRemoveAllConfirmation = true
                }
                .disabled(store.watchlist.isEmpty)
            }
            Section("About") {
                LabeledContent("Version", value: version)
                LabeledContent("Data source", value: "Yahoo Finance (unofficial)")
                if let repoURL = URL(string: "https://github.com/kanharithsok/stock-peek") {
                    Link("GitHub repository", destination: repoURL)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .alert("Remove all tracked stocks?", isPresented: $showRemoveAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove All", role: .destructive) {
                store.removeAll()
            }
        } message: {
            let count = store.watchlist.count
            Text("This removes all \(count) \(count == 1 ? "symbol" : "symbols") from your watchlist.")
        }
    }

    private var version: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let build, !build.isEmpty {
            return "\(shortVersion) (\(build))"
        }
        return shortVersion
    }
}
