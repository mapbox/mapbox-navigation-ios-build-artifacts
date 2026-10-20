// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.34.0-rc.1"
let navNativeVersion: Version = "324.34.0-rc.1"

let version = "3.34.0-rc.1"

let binaries = ["MapboxCoreMaps": "f79223a61eddf18130b72397567f0f6d3ca62d09ee748dc8c49fd4c9d81bbc5a", 
"MapboxDirections": "52c821921ba85c22787070fe77747be14f72ec50273fdda2094d3365d0d29ca7", 
"MapboxMaps": "a7a553e7776bbc30fce66a64186692c80b3dd84f36e0f71a85cd9a1925bcc6ca", 
"MapboxNavigationCore": "6bdd8614c74c35bc1be42efe4e1a71712e095f5b2a1d11b69e6f5c9a41711e1d", 
"MapboxNavigationUIKit": "9320103363b6501850dfb14eb6bec66115694e46673d4fe97eb00e48485fad03", 
"_MapboxNavigationHelpers": "a5f023ef7b02174c7483baa8c1b2bedcabed37ddd8d088f5ab5612ae72c2cf74", 
"_MapboxNavigationLocalization": "43317fa6f7b8785d2e90649c6ca14147eb9a1ec7b987c0d144d4b82cda0bbe99", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "6e6b9a7743f9ba2093b08c48b88cac3d697c4f3fc7fd8fe81109da4ddd201a4d", 
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
