// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CryptoAppKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "PriceFeed", targets: ["PriceFeed"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "PriceFeed", dependencies: ["Domain"]),
        .target(name: "Persistence", dependencies: ["Domain"]),
        .target(name: "DesignSystem"),
        .target(
            name: "Features",
            dependencies: ["Domain", "PriceFeed", "Persistence", "DesignSystem"]
        ),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "PriceFeedTests", dependencies: ["PriceFeed", "Domain"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Domain"]),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features", "PriceFeed", "Persistence", "Domain"]
        ),
    ]
)
