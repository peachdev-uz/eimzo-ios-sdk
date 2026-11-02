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
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.3.0-dev.6/EimzoSDK.xcframework.zip",
            checksum: "09608b414bca225ca961b429c155d00516257c45f57f106bb39bb0c18a5aeee9"
        ),
        .binaryTarget(
            name: "Pfx2qr",
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.3.0-dev.6/Pfx2qr.xcframework.zip",
            checksum: "21407a4fe64a647e27e37e887dc9ea4a397cc61810e8890b300c223039390e9b"
        ),
    ]
)
