# Changelog

## [1.0.4] - 2026-06-04

- 🔐 **Security:** Keys.json now written with
  `.completeFileProtectionUntilFirstUserAuthentication`. The file is
  encrypted at rest with a passcode-derived key — `iMazing` / iTunes
  backups, jailbroken-device filesystem reads, and `iCloud Drive` sync
  only see opaque ciphertext.

## [1.0.3] - 2026-06-04

- ✨ Confirmation dialog only shows for in-app QR scans now. External
  deeplinks (e.g. `onOpenURL`) sign directly.

## [1.0.0] - 2026-06-04

Initial closed-source XCFramework release.
