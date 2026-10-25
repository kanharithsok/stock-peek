import AppKit
import SwiftUI

@main
struct MacStockWidgetApp: App {
    @StateObject private var store = Store()
    @StateObject private var settings = SettingsStore()

    init() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else { return }
            MainActor.assumeIsolated {
                guard window.level == .statusBar else { return }
                Self.fitPanelToContent(window, attempt: 0)
            }
        }
    }

    static func fitPanelToContent() {
        guard let window = NSApp.windows.first(where: { $0.level == .statusBar }) else { return }
        fitPanelToContent(window, attempt: 0)
    }

    @MainActor
    static func bringSettingsToFront(attempt: Int = 0) {
        NSApp.activate()

        let settingsWindow = NSApp.windows.first {
            $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window"
        } ?? NSApp.windows.first {
            $0.level != .statusBar && $0.title.localizedCaseInsensitiveContains("settings")
        }

        if let settingsWindow {
            if let popover = NSApp.windows.first(where: {
                $0.isVisible && String(describing: type(of: $0)).contains("MenuBarExtraWindow")
            }), settingsWindow.frame.intersects(popover.frame) {
                settingsWindow.center()
            }
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard attempt < 20 else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            bringSettingsToFront(attempt: attempt + 1)
        }
    }

    private static func fitPanelToContent(_ window: NSWindow, attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            guard let content = window.contentView else { return }
            let fitting = content.fittingSize
            let currentHeight = content.frame.height
            let delta = fitting.height - currentHeight
            guard abs(delta) > 1 else { return }
            var frame = window.frame
            frame.size.height += delta
            frame.origin.y -= delta
            window.setFrame(frame, display: true)
            guard attempt < 10 else { return }
            fitPanelToContent(window, attempt: attempt + 1)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .accessibilityLabel("Stock Widget")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store, settings: settings)
        }
    }
}
