// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StockPeek",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StockPeek",
            path: "Sources/StockPeek"
        )
    ]
)
