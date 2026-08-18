// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Islandify",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "IslandifyDomain", targets: ["IslandifyDomain"]),
        .executable(name: "IslandifyDomainChecks", targets: ["IslandifyDomainChecks"])
    ],
    targets: [
        .target(
            name: "IslandifyDomain",
            path: "Shared/Domain"
        ),
        .executableTarget(
            name: "IslandifyDomainChecks",
            dependencies: ["IslandifyDomain"],
            path: "Shared/DomainChecks"
        ),
        .testTarget(
            name: "IslandifyDomainTests",
            dependencies: ["IslandifyDomain"],
            path: "IslandifyTests",
            exclude: ["Info.plist"]
        )
    ]
)
