// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.8.0"
let navNativeVersion: Version = "321.0.0"

let version = "3.5.0"

let binaries = ["MapboxCoreMaps": "5fa0cc70cc9ae5734096d325c638ed1bbbe5e1a7d1a1817dcc54922b14488716", 
"MapboxDirections": "5dcda5f3184c1cb37ca1e1e6f7fcd06cb7c8487c02ed1357e9aa0be77f88bff6", 
"MapboxMaps": "2abdddae11a2ca7e5c9d28ecf10b59d2b9c4e5efde1afaea378a3794965aff28", 
"MapboxNavigationCore": "bce6978b18dcd41d0354c480506faf9d4b72b5dced271bcaf4633ac1ba4a5001", 
"MapboxNavigationUIKit": "986af8c93ae51e5e5474b7d143d3a3c0a9e2871b75d359b2f33b0af7b94bc82a", 
"Turf": "8939eb0397390b43cb5af90e2597f858c704ebc07f4973799684a7a9a87e5946", 
"_MapboxNavigationHelpers": "a905f43b14466876da35d5cbbc76b991cf99efb824af5f5a145e756f47704954", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "19936d0840f195b996588d53f33f3e0f7cbe30f196783d10b2842539675bd308", 
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
