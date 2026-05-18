// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let commonVersion: Version = "24.21.5"
let navNativeVersion: Version = "324.21.5"

let version = "3.21.5"

let binaries = ["MapboxCoreMaps": "04e154695fec9e4b3a831c2a9dc12407e507a642618cf2a0f362c63c24c33b38", 
"MapboxDirections": "f9a614669fa5d6d128704b76e43d60733050c546eb358586321e245d1ac8ecf9", 
"MapboxMaps": "74a1ed6f3e21f8b164f1f2716f0fc09bf3d2f92fabfbb0f85640625f5c0030de", 
"MapboxNavigationCore": "b06568ddf005346bc1037e8bd18bab67162aeb73b495855258d590341d2da543", 
"MapboxNavigationUIKit": "906b96a25d35718fd1568633dd8ecc8083ba94777f572b3424344fabaa87580b", 
"_MapboxNavigationHelpers": "38e9aa36233c4971c4159d4ef089e97ffb4d30ed0adf320b76eeb9a05cfa969c", 
"_MapboxNavigationLocalization": "4198d9efe9203e6546fd618e386f43dda6531de1ac7dd3c45bb70209237c8d77", 
 ]

let libraries = ["MapboxNavigationCustomRoute": "8182313f909d48b98d05aceb27967ae6a2530a99f91d9572e398094822c7f5d6", 
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
