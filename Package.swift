// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WallClockTime",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WallClockTime", targets: ["WallClockTime"]),
    ],
    targets: [
        .target(name: "WallClockTime"),
        .testTarget(name: "WallClockTimeTests", dependencies: ["WallClockTime"]),
    ],
    swiftLanguageModes: [.v5]
)
