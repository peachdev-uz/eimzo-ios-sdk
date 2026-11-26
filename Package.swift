// swift-tools-version: 5.9
// E-IMZO Mobile SDK for iOS — public distribution manifest.
//
// This package declares ONE `.binaryTarget` pointing at the pre-built
// `EimzoSDK.xcframework` hosted on GitHub Releases. SwiftPM embeds it at
// `App.app/Frameworks/`.
//
// Up to 2.7 a second one went with it, `Pfx2qr`: Go's PFX → QR converter.
// Since 2.8.0 a PFX key file is read by Swift code inside EimzoSDK, and the
// SDK carries no Go.
//
// Build pipeline (private repo):
//   1. `bash Scripts/build-xcframework.sh` produces
//      `build/EimzoSDK.xcframework.zip` plus its `.sha256` file.
//   2. Upload the zip to the GitHub Release.
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
            url: "https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.8.0/EimzoSDK.xcframework.zip",
            checksum: "781de40d7485fa7c18bd74a2456c033350c93da403e4af00e4571b262a513b7f"
        ),
    ]
)
