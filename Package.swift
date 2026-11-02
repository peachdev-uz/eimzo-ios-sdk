// swift-tools-version: 5.9
// E-IMZO Mobile SDK for iOS — public distribution manifest.
//
// This package declares TWO `.binaryTarget`s pointing at the pre-built
// `.xcframework` files hosted on GitHub Releases. Both are linked into
// the `EimzoSDK` library product so SwiftPM embeds them side-by-side
// at `App.app/Frameworks/` — NOT nested. The 1.1.4 layout (Pfx2qr
// inside EimzoSDK.framework/Frameworks/) was rejected by App Store
// Connect with errors 90205/90206/90035; 1.1.5+ ships them as siblings.
//
// Build pipeline (private repo):
//   1. `bash Scripts/build-xcframework.sh` produces
//      `build/EimzoSDK.xcframework.zip` and `build/Pfx2qr.xcframework.zip`
//      plus matching `.sha256` files.
//   2. Upload BOTH zips to the same GitHub Release.
//   3. Update the `url:` + `checksum:` fields below, commit, tag.
//
import PackageDescription

let package = Package(
    name: "EimzoSDK",
    platforms: [.iOS(.v16)],
    products: [
        // Single library — adding it pulls BOTH binary targets in,
        // and Xcode embeds them at the app's Frameworks/ root.
        .library(name: "EimzoSDK", targets: ["EimzoSDK", "Pfx2qr"]),
    ],
    targets: [
        .binaryTarget(
            name: "EimzoSDK",
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.3.0-dev.5/EimzoSDK.xcframework.zip",
            checksum: "6100b24cc29994032abe96bd4e4e063e7fd9540d9b2a7c08a889ec3a4c4fa2e1"
        ),
        .binaryTarget(
            name: "Pfx2qr",
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.3.0-dev.5/Pfx2qr.xcframework.zip",
            checksum: "068ca3b11176f5404fab72c2fd18f6de3627317448b32feeacd2b8443a6537ff"
        ),
    ]
)
