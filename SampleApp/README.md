# Mapbox Navigation SDK — `Package.swift` Verification Sample

A minimal iOS app whose only job is to prove that the repo's root
[`Package.swift`](../Package.swift):

1. Resolves cleanly in Swift Package Manager.
2. Downloads every binary `xcframework` the manifest references.
3. Links every library product it exports:
   - `MapboxNavigationCore`
   - `MapboxNavigationUIKit`
   - `MapboxDirections`
   - `MapboxNavigationCustomRoute`
4. Can be imported and instantiated at runtime.

`ContentView.swift` imports every product at the top of the file and
exercises a symbol from each one, so a successful build + run proves the
manifest's product wiring is correct end to end.

## Layout

```
SampleApp/
├── README.md                             ← this file
├── project.yml                           ← xcodegen spec (local SPM dep on ..)
├── .gitignore                            ← excludes the generated .xcodeproj
└── MapboxNavigationSample/
    ├── Info.plist
    ├── MapboxNavigationSampleApp.swift
    └── ContentView.swift                 ← one runtime check per product
```

The `MapboxNavigationSample.xcodeproj` is **not** committed — it is
generated from `project.yml` via
[xcodegen](https://github.com/yonaskolb/XcodeGen).

## Prerequisites

- **Xcode 15.3+** (Swift 5.9 toolchain or newer).
- **xcodegen** — `brew install xcodegen`.
- **Mapbox download token in `~/.netrc`** so SwiftPM can fetch the binary
  xcframeworks from `api.mapbox.com`:

  ```
  machine api.mapbox.com
    login mapbox
    password sk.YOUR_SECRET_DOWNLOAD_TOKEN
  ```

  The token must have `DOWNLOADS:READ` scope for both `navsdk-v3-ios` and
  `mapbox-navigation-custom-route-ios`.

> **No runtime access token is required.** This sample never hits the
> Directions API or loads map tiles; it only verifies that the
> manifest's artifacts download, link, and can be instantiated. If you
> extend the sample to render a map or request a route, add
> `MBXAccessToken` (a `pk.…` token) to `Info.plist` yourself.

## 1. Generate the Xcode project

From the repository root:

```bash
cd SampleApp
xcodegen generate
```

You should see:

```
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at …/SampleApp/MapboxNavigationSample.xcodeproj
```

Regenerate any time `project.yml` changes.

## 2. Verify `Package.swift`

### 2a. Resolve dependencies only (fastest signal)

```bash
cd SampleApp
xcodebuild \
  -resolvePackageDependencies \
  -project MapboxNavigationSample.xcodeproj \
  -scheme MapboxNavigationSample
```

A clean exit code (0) means:

- every binary target downloaded,
- every SHA256 checksum matched what the manifest declares,
- every transitive package (`mapbox-common-ios`, `mapbox-navigation-native-ios`,
  `turf-swift`) resolved to a version consistent with the manifest's
  `exact:` constraints.

If a checksum is wrong, `xcodebuild` prints both the expected and the
actual value, e.g.:

```
checksum of downloaded artifact of binary target 'MapboxDirections'
  (6740caf04592…) does not match checksum specified by the manifest
  (b6efc3261fb4…)
```

The first hex string is what's actually hosted at `api.mapbox.com`; the
second is what `Package.swift` declares.

### 2b. Compile & link for the simulator

```bash
cd SampleApp
xcodebuild build \
  -project MapboxNavigationSample.xcodeproj \
  -scheme MapboxNavigationSample \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

`** BUILD SUCCEEDED **` proves every public symbol referenced by
`ContentView.swift` resolved against the downloaded `.xcframework`s —
i.e. the manifest's product wiring is correct, and both `arm64` and
`x86_64` simulator slices are usable.

### 2c. Run in Xcode

1. `open MapboxNavigationSample.xcodeproj`
2. Pick any iOS Simulator (iOS 14 or later).
3. Hit Run.

You should see a list with one row per product, each marked ✅ once the
symbol was resolved and exercised at runtime.

## Spot-checking an arbitrary release

The sample is a convenient regression harness — point it at any tagged
release by checking out only that tag's `Package.swift`:

```bash
# From the repo root
git checkout v3.20.0 -- Package.swift

# Clear SPM caches so checksums are re-verified from the network
rm -rf ~/Library/Caches/org.swift.swiftpm \
       SampleApp/MapboxNavigationSample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

cd SampleApp
xcodebuild -resolvePackageDependencies \
  -project MapboxNavigationSample.xcodeproj \
  -scheme MapboxNavigationSample

# Restore main's Package.swift when done
git checkout main -- Package.swift
```

## Notes

- The deployment target is pinned to **iOS 14**, matching the
  `platforms: [.iOS(.v14)]` declaration in `Package.swift`.
- `Package.resolved` is already ignored by the repo's root `.gitignore`.
