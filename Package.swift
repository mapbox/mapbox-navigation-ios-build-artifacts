// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.30.0"
let navNativeVersion: Version = "324.30.0"

let version = "3.30.0"

let binaries = ["MapboxCoreMaps": "1b5359cc9ab5291dc443152c145c329e2697fa111b5e1040067697210ecb6a50", 
"MapboxDirections": "b03770e0cb53c4e627c091aa2095d8edb5bae51e4cae9918b27b76d524124539", 
"MapboxMaps": "1774b1a40090adba766c26f5709cb4b67d4e26c99f43b6c6429c590c624fe452", 
"MapboxNavigationCore": "fc9139e6f73c968613a7180beb505958a8d30697e9d17a785988c47108b47371", 
"MapboxNavigationUIKit": "37b6679788c6293a2978900e5fded8d06278d8fd9ebc949c9fe16b9f1f927640", 
"_MapboxNavigationHelpers": "32df2bc2b975fd78ad4141072d2329b1cfb29f0ee73ffe893eed92021aaf6370", 
"_MapboxNavigationLocalization": "10282bb7c33e4a7d8e36745081d0ac560bd40c4a4661c9aa724149c66d37e99d", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "8580abfea231dd482e474791ea73edc21c7ca53bbcf99b7fbd3d9c8538cf4660", 
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
