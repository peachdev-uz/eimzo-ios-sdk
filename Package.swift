// swift-tools-version: 5.9
// E-IMZO Mobile SDK for iOS — public distribution manifest.
//
// This package only declares a `.binaryTarget` pointing at the
// pre-built `.xcframework` hosted on GitHub Releases. No source
// code is shipped — integrators get the SDK as a closed binary.
//
// Build pipeline (private repo):
//   1. `bash Scripts/build-xcframework.sh` produces
//      `build/EimzoSDK.xcframework.zip` + its SHA-256.
//   2. `gh release create vX.Y.Z build/EimzoSDK.xcframework.zip`
//   3. Update the `url:` + `checksum:` fields below, commit, tag.
//
import PackageDescription

let package = Package(
    name: "EimzoSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "EimzoSDK", targets: ["EimzoSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "EimzoSDK",
            // Replace with the actual GitHub Release URL after `gh release create`:
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/1.1.1/EimzoSDK.xcframework.zip",
            // Output of `swift package compute-checksum EimzoSDK.xcframework.zip`:
            checksum: "5469550aa7b383d02d416e5f26477df1a8524f7952e09324c6f12dc8dd2c4c24"
        ),
    ]
)
