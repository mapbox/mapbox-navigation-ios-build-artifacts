// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.9.0"
let navNativeVersion: Version = "322.1.0"

let version = "3.6.1"

let binaries = ["MapboxCoreMaps": "dadf72d8f07ff036837fb47c91287c03115884bf2e3339f4fd5e08bdaf242134", 
"MapboxDirections": "6d8129ceda7e597786384ee5e092032241b98460c133191e89ba22f15e4eb497", 
"MapboxMaps": "0c91324f88552c047962e3ed64c79058f230afc08182950d81d09d78802c9013", 
"MapboxNavigationCore": "a08b2aaff7d099a22e27f18e659616fbe1f86aeee05c4c2294bfc1dc202bdcde", 
"MapboxNavigationUIKit": "c080d9057a87611a298de52bad575ba0cb75c02c58f0150092a9ff2be299a7bd", 
"_MapboxNavigationHelpers": "79d320ccbbc5dc6f01b92cab85e0ce38cb40f5fec771d82ddbb83bb2082aec68", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "81cc3d8796aca4ee38635fa9e403889a92d06e34fe72d5cfc844a82261cb58f2", 
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
            dependencies: binaries.keys.map { .byName(name: $0) } + [
                .product(name: "MapboxCommon", package: "mapbox-common-ios"),
                .product(name: "MapboxNavigationNative", package: "mapbox-navigation-native-ios"),
            ],
            path: "Sources/.empty/MapboxNavigationCoreWrapper"
        ),
        .target(
            name: "MapboxNavigationUIKitWrapper",
            dependencies: [
                "MapboxNavigationCoreWrapper",
            ],
            path: "Sources/.empty/MapboxNavigationUIKitWrapper"
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
