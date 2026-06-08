# Changelog

## [1.1.2] - 2026-06-08

### Fix: FeitianSDK module dependency leakage

Integrator loyihalarida `Unable to resolve module dependency: 'FeitianSDK'`
xatosi chiqayotgan edi. Static FeitianSDK.xcframework consumer-da alohida
modul sifatida ko'rinmas, lekin swiftinterface uni qidirardi.

Yechim: `@_implementationOnly import FeitianSDK` — swiftinterface'dan
yashirildi. Runtime ishlash o'zgarmadi, Mach-O ichida symbol'lar
xuddi avvalgidek mavjud.


## [1.1.1] - 2026-06-08

### Security: USB token API lockdown

USB token bilan ishlash endi **faqat** license-gated EimzoSDK UI yo'li
orqali mumkin (`EImzoView` → `HomeView` → `TokenImportView` →
`EImzoSigner.signWithUsbTokenKey`). Diagnostic API butunlay olib tashlandi.

- 🔒 **TokenDemo o'chirildi** — `run`, `signDeeplink`,
  `compareRawVsTransport` public yordamchi metodlari edi. Ular
  `LicenseEnforcement.ensureAllowed()` ni chetlab o'tar edi.
- 🔒 **`CryptoTokenKit`, `CryptoTokenKitSession`, `FeitianReader`,
  `FeitianSession`, `FeitianError`, `CTKDebugLog`** — `public` →
  `internal`. Faqat SDK ichidagi `HomeView` / `TokenImportView` /
  `EImzoSigner` ishlatadi.

Integrator-facing API o'zgarmadi — `PfxKey(keyType: .usbToken)` saqlash
va imzolash xuddi NFC va PFX kalitlari kabi avtomatik license-gated.

## [1.1.0] - 2026-06-08

### USB token orqali imzolash qo'shildi

Lightning/USB-C portga ulangan USB CCID tokenlar (Feitian eJava,
ePass2003, Identiv SCR3xx) orqali to'liq E-IMZO sign flow. iOS 16+ ning
ichki CryptoTokenKit orqali ishlaydi — token MFi sertifikatlangan
bo'lishi shart emas.

- ✨ **`AddKeyView`** ga 4-source "USB Token" tugmasi.
- ✨ **`HomeView`** auto-detect — CCID slot mavjud, lekin `.usbToken`
  kalit import qilinmagan bo'lsa, "USB Token aniqlandi" banneri.
- ✨ **`KeyCard`** ga key-type chip ("NFC" / "Token").
- ✨ **`EImzoSigner.signWithUsbTokenKey`** — `.usbToken` kalit turi
  uchun sign yo'li. `m.e-imzo.uz` server tomonidan PKCS#7 qabul
  qilinishi tasdiqlangan.

**Cheklov:** Lightning iPhone'da Apple Lightning-to-USB Camera Adapter
(yoki MFi-certified ekvivalent) kerak. USB-C iPhone 15+ Pro / iPad'da
to'g'ridan-to'g'ri USB-C → USB-A kabel ishlaydi.

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
