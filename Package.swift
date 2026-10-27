// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.33.1"
let navNativeVersion: Version = "324.33.1"

let version = "3.33.1"

let binaries = ["MapboxCoreMaps": "c615fe2e62fe80146cc0f0031513990b6b8f3e286190ef6a6dc46db82e807153", 
"MapboxDirections": "f72db888fcba1604e73e132a734601c5454f2ecefa8116a4ee772f577bd80024", 
"MapboxMaps": "5e836088636ab787b4defb3a6011eb827ef5c99ddb0ce3b1a60225367c86a8a2", 
"MapboxNavigationCore": "e2ba79540b86eb9760d7bf38de73f445fdac21461cbaa4b8598a342233667cbb", 
"MapboxNavigationUIKit": "bf5ead7994be6b6e6b1667db7c5acdf0161dd40d7403de4194cd85b8d68407e2", 
"_MapboxNavigationHelpers": "7980c82dfad142a40323f654aa63d7b4f8cfa58177c75cf6d92d994d58ae9617", 
"_MapboxNavigationLocalization": "7ef8c1995ff7d64f7a181d8f0e534c5c0e935555d5fa5841f575da8fa908b517", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "8d278eab9a7addd32f990a2d9e7f6d629e04b10762229c13c96db218a852b98d", 
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
