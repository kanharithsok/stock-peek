// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacStockWidget",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MacStockWidget",
            path: "Sources/MacStockWidget"
        )
    ]
)
