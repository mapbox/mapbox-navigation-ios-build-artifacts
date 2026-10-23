// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.30.7"
let navNativeVersion: Version = "324.30.7"

let version = "3.30.7"

let binaries = ["MapboxCoreMaps": "af976e04cd049e56a690bb6549b221129eab0bc8e3287bbc8eda09b579e44a58", 
"MapboxDirections": "46c606a4ee1c5c2766a8b902e1b711a29ee58cbca1b1ebd6dbaa62ecd6e0f3eb", 
"MapboxMaps": "c10198bcd30c0b39c3016a29f6319000f5e83cc01cd5ffc66a0be24211a59856", 
"MapboxNavigationCore": "5d8b3377e0fbd99c1b482af7e5b1421fa04c3f7f6f145173473865d1dff02933", 
"MapboxNavigationUIKit": "2e0e45d54e671639d41814ab2d26832a54f617b920e32111024a497f26851c9b", 
"_MapboxNavigationHelpers": "13904a5663156867f62e66e2c43a6fb6a28dc165d4876fd6c89fba2960e32895", 
"_MapboxNavigationLocalization": "e21efa28123210fa2c70431f6d56f87109f9f5489c77bfaa3a93beb6c0efb4dd", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "e02fb1e6566f8b8bc107b9a69d1506b25feaff07791cbb3d4e71cad7aaebd129", 
 ]

enum FrameworkType {
    case release
    case staging
    case local
}

let frameworkType: FrameworkType = .release

let package = Package(
    name: "MapboxNavigation",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "MapboxNavigationCore",
            targets: ["MapboxNavigationCoreWrapper"]
        ),
        .library(
            name: "MapboxNavigationUIKit",
            targets: ["MapboxNavigationUIKitWrapper"]
        ),
        .library(
            name: "MapboxDirections",
            targets: ["MapboxDirectionsWrapper"]
        ),
        .library(
            name: "MapboxNavigationCustomRoute",
            targets: ["MapboxNavigationCustomRouteWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", exact: commonVersion),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: navNativeVersion),
    ],
    targets: binaryTargets() + libraryTargets() + [
        .target(
            name: "MapboxNavigationCoreWrapper",
            dependencies:
            binaries.keys
                .filter { $0 != "MapboxNavigationUIKit" }
                .map { .byName(name: $0) }
                + [
                    .product(name: "MapboxCommon", package: "mapbox-common-ios"),
                    .product(name: "MapboxNavigationNative", package: "mapbox-navigation-native-ios"),
                ],
            path: "Sources/.empty/MapboxNavigationCoreWrapper"
        ),
        .target(
            name: "MapboxNavigationUIKitWrapper",
            dependencies: [
                "MapboxNavigationUIKit",
                "MapboxNavigationCoreWrapper",
            ],
            path: "Sources/.empty/MapboxNavigationUIKitWrapper"
        ),
        .target(
            name: "MapboxDirectionsWrapper",
            dependencies: [
                "MapboxDirections",
                .product(name: "MapboxCommon", package: "mapbox-common-ios"),
            ],
            path: "Sources/.empty/MapboxDirectionsWrapper"
        ),
        .target(
            name: "MapboxNavigationCustomRouteWrapper",
            dependencies: libraries.keys.map { .byName(name: $0) } + [
                "MapboxNavigationCoreWrapper",
            ],
            path: "Sources/.empty/MapboxNavigationCustomRouteWrapper"
        ),
    ]
)

func binaryTargets() -> [Target] {
    binaries.map { binaryName, checksum in
        binaryTarget(binaryName: binaryName, checksum: checksum, packageName: "navsdk-v3-ios")
    }
}

func libraryTargets() -> [Target] {
    libraries.map { binaryName, checksum in
        binaryTarget(binaryName: binaryName, checksum: checksum, packageName: "mapbox-navigation-custom-route-ios")
    }
}

func binaryTarget(binaryName: String, checksum: String, packageName: String) -> Target {
    switch frameworkType {
    case .release, .staging:
        let host = frameworkType == .release ? "api.mapbox.com" : "cloudfront-staging.tilestream.net"
        return Target.binaryTarget(
            name: binaryName,
            url: "https://\(host)/downloads/v2/\(packageName)" +
                "/releases/ios/packages/\(version)/\(binaryName).xcframework.zip",
            checksum: checksum
        )
    case .local:
        return Target.binaryTarget(
            name: binaryName,
            path: "XCFrameworks/\(binaryName).xcframework"
        )
    }
}
