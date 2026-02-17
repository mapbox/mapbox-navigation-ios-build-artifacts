// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.20.0-SNAPSHOT-02-12--15-15.git-96870d2"
let navNativeVersion: Version = "324.20.0-SNAPSHOT-02-12--15-15.git-96870d2"

let version = "3.20.0-SNAPSHOT-02-12--15-15.git-96870d2"

let binaries = ["MapboxCoreMaps": "be372fdb287866b24299f52ff6323d3461d9289c07a03dce618434e62c51ed9d", 
"MapboxDirections": "5e4d23aeb4a60117f2cb5a32174b0d1fe1acf854ed69b932bec12cf4c842708d", 
"MapboxMaps": "a9d0ebbb882cda18a916003e91eea741329f2089a2e6acbf27fcc253b1fe11eb", 
"MapboxNavigationCore": "b25f88f211f51459c9f6dd147eb5e3b0b6dc56614ace69bcaf50068e79a13ae4", 
"MapboxNavigationUIKit": "a6da48f1871480febd94c2b60e7703f8f6aa72197afe28ea5be9162964a16818", 
"_MapboxNavigationHelpers": "108715d132ac298536b845ae06396b49296ba55bb9e6fa00e5a9bdbe10b4cb74", 
"_MapboxNavigationLocalization": "ca46abbe2453a96f2370f2de40c398096e36e199648c51bc8c6b16c7910ffdd5", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "0a159e5842e822402b20a4171ae6d66fccb707fe06c2e0eaa1970197fe57f42a", 
 ]

enum FrameworkType {
    case release
    case snapshot
    case staging
    case local
}

let frameworkType: FrameworkType = .snapshot

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
    case .release, .staging, .snapshot:
        let host = frameworkType == .staging ? "cloudfront-staging.tilestream.net" : "api.mapbox.com"
        let variant = frameworkType == .snapshot ? "snapshots" : "releases"
        return Target.binaryTarget(
            name: binaryName,
            url: "https://\(host)/downloads/v2/\(packageName)" +
                "/\(variant)/ios/packages/\(version)/\(binaryName).xcframework.zip",
            checksum: checksum
        )
    case .local:
        return Target.binaryTarget(
            name: binaryName,
            path: "XCFrameworks/\(binaryName).xcframework"
        )
    }
}
