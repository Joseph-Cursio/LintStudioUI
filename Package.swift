// swift-tools-version: 6.2
import PackageDescription

let kSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self)
]

let kPackage = Package(
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
            swiftSettings: kSwiftSettings
        ),
        .target(
            name: "LintStudioUI",
            dependencies: ["LintStudioCore"],
            swiftSettings: kSwiftSettings
        ),
        .testTarget(
            name: "LintStudioCoreTests",
            dependencies: ["LintStudioCore"],
            swiftSettings: kSwiftSettings
        )
    ]
)
