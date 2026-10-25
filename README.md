# MacStockWidget

A lightweight macOS menu bar app for tracking stock quotes from Yahoo Finance.

<img src="Resources/AppIcon.png" width="128" alt="MacStockWidget icon">

## Features

- Live quotes in the menu bar, refreshed on a configurable interval
- Search and add symbols to your watchlist
- Auto-sizing popover that adapts to the number of tracked stocks
- Launch at login support
- Native SwiftUI app with no third-party dependencies

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6.0 / Xcode 16 or later

## Build and run

```bash
swift build
swift run
```

To build a proper `.app` bundle with an icon and ad-hoc code signature:

```bash
./scripts/build_app.sh
open dist/MacStockWidget.app
```

To build and install into `/Applications`:

```bash
./scripts/install.sh
```

## Usage

1. Launch the app — a chart icon appears in the menu bar.
2. Click the icon and search for a ticker symbol (for example `AAPL`) to add it.
3. Open Settings to change the refresh interval or enable launch at login.

## Project structure

```
Sources/MacStockWidget/
├── App.swift         # App entry point and menu bar scene
├── MenuBarView.swift # Menu bar popover UI
├── Models.swift      # Quote models
├── Settings.swift    # Settings and launch-at-login
├── Store.swift       # Watchlist and refresh logic
└── YahooClient.swift # Yahoo Finance API client

Resources/            # Info.plist and app icon
scripts/              # Build and install scripts
```

## Notes

Quote data comes from Yahoo Finance's unofficial API and may be delayed. This
project is for personal use and is not affiliated with Yahoo.
