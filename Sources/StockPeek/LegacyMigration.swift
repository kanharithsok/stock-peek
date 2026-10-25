import Foundation

/// Migrates preferences from the app's previous bundle identifier.
enum LegacyMigration {
    private static let legacyDomain = "com.ks.macstockwidget"
    private static let migrationKey = "didMigrateFromMacStockWidget"

    static func runIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        if let legacy = UserDefaults(suiteName: legacyDomain) {
            for key in ["watchlist", "cachedQuotes", "refreshInterval"]
            where defaults.object(forKey: key) == nil {
                if let value = legacy.object(forKey: key) {
                    defaults.set(value, forKey: key)
                }
            }
        }

        defaults.set(true, forKey: migrationKey)
    }
}
