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

    init() {
        isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update login item: \(error)")
        }
        isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct SettingsView: View {
    @ObservedObject var store: Store
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.isLaunchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
                Picker("Refresh interval", selection: $settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval.rawValue)
                    }
                }
            }
            Section("Watchlist") {
                Button("Remove all tracked stocks", role: .destructive) {
                    store.removeAll()
                }
                .disabled(store.watchlist.isEmpty)
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Data source", value: "Yahoo Finance (unofficial)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
