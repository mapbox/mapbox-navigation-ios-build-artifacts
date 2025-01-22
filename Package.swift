// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.10.0-beta.2"
let navNativeVersion: Version = "323.0.0-beta.2"

let version = "3.7.0-beta.1"

let binaries = ["MapboxCoreMaps": "20d5b6b0927820518002d79b4f79130cf2a3ee3f7f347ac4c69db247327de8f0", 
"MapboxDirections": "0ad7d8f67bfbde4e4905a163e8a9d46a1c493acaf299a1d3e04110b314ec36ff", 
"MapboxMaps": "35d9cc0702a51188e453f01c435fd97ab2554cca122cfd4c2c41e65316a1938b", 
"MapboxNavigationCore": "2a3e122682c82b161fa90bc39c850ad4dcb8e0900baec294da70984ce0016eed", 
"MapboxNavigationUIKit": "cefe7c74c33df5fbe78f467e237d4da294e1cc6e038bf0d7643cca86ba75dcbe", 
"_MapboxNavigationHelpers": "0a6087695bf241519d6b6e410b7aab2860207408f7799b7e4552ecaf379fc643", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "97a9b5b12fbaef3835c2f0e79cb36956b3b4ae4034cf60c368f7828b000341b6", 
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
