// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self)
]

let package = Package(
    name: "LintStudioUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "LintStudioCore",
            targets: ["LintStudioCore"]
        ),
        .library(
            name: "LintStudioUI",
            targets: ["LintStudioUI"]
        )
    ],
    targets: [
        .target(
            name: "LintStudioCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "LintStudioUI",
            dependencies: ["LintStudioCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "LintStudioCoreTests",
            dependencies: ["LintStudioCore"],
            swiftSettings: swiftSettings
        )
    ]
)
