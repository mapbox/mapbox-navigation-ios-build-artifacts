import SwiftUI
import CoreLocation

// Pull in every product declared by ../Package.swift so a successful build
// proves all four library products link correctly against the binary
// xcframeworks downloaded by SwiftPM.
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxNavigationCustomRoute

struct ContentView: View {
    @State private var status: [LinkCheck] = []

    var body: some View {
        NavigationView {
            List(status) { check in
                HStack(alignment: .firstTextBaseline) {
                    Text(check.ok ? "✅" : "❌")
                    VStack(alignment: .leading) {
                        Text(check.module).font(.headline)
                        Text(check.detail)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitle("Package.swift verification")
        }
        .onAppear(perform: runLinkChecks)
    }

    private func runLinkChecks() {
        status = [
            check(module: "MapboxDirections") {
                let wp1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
                let wp2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
                let opts = NavigationRouteOptions(waypoints: [wp1, wp2])
                return "NavigationRouteOptions built with \(opts.waypoints.count) waypoints"
            },
            check(module: "MapboxNavigationCore") {
                let config = CoreConfig()
                let provider = MapboxNavigationProvider(coreConfig: config)
                _ = provider.mapboxNavigation
                return "MapboxNavigationProvider initialized"
            },
            check(module: "MapboxNavigationUIKit") {
                // Reference a type from the UIKit module to force linkage.
                let mirror = String(describing: NavigationViewController.self)
                return "NavigationViewController symbol resolved (\(mirror))"
            },
            check(module: "MapboxNavigationCustomRoute") {
                // `import MapboxNavigationCustomRoute` at the top of this
                // file is what exercises the product. If the xcframework or
                // product wiring is broken, this file would not compile.
                return "Module imported (binary product resolved by SwiftPM)"
            },
        ]
    }

    private func check(module: String, _ body: () throws -> String) -> LinkCheck {
        do {
            let detail = try body()
            return LinkCheck(module: module, ok: true, detail: detail)
        } catch {
            return LinkCheck(module: module, ok: false, detail: "\(error)")
        }
    }
}

private struct LinkCheck: Identifiable {
    let id = UUID()
    let module: String
    let ok: Bool
    let detail: String
}
