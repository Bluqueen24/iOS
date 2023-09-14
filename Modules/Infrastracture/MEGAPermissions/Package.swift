// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAPermissions",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPermissions",
            targets: ["MEGAPermissions"]
        ),
        .library(
            name: "MEGAPermissionsMock",
            targets: ["MEGAPermissionsMock"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGAPermissions",
            dependencies: [],
            swiftSettings: settings
        ),
        .target(
            name: "MEGAPermissionsMock",
            dependencies: ["MEGAPermissions"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPermissionsTests",
            dependencies: ["MEGAPermissions", "MEGAPermissionsMock"],
            swiftSettings: settings
        )
    ]
)
