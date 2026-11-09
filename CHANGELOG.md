# Changelog

## 2.4.0 — 2026-11-09

**New: the Keys API («Kalitlar API»), for integrators YT has given the
permission.** YT turns it on at the integrator's request, after the contract,
for all of its apps; without it both methods return `api_not_allowed`.
`EImzoView` stays open to every registered integrator, and users keep adding
their keys there.

- `EImzoAPI.getKeys(config:)` returns the keys the user has added to the SDK
  on this phone that can be used in the configured environment, as JSON:
  `{"status":"ok","keys":[{"id":…,"pinfl":…,"name":…,"validFrom":"yyyy-MM-dd","validTo":"yyyy-MM-dd"}]}`.
  Every kind of key, expired ones included, the default key first. Nothing
  else about a key is returned — no STIR, organisation, key data or password.
- `EImzoAPI.sign(keyId:deepLink:config:)` signs an `EImzoSignLink` request
  with one of those keys through the SDK's own sign sheet, shown over your
  top-most view controller. The sheet shows the site, the hash and the key;
  the user taps IMZOLASH and types the password or PIN there and only there.
  It returns `{"status":"signed"}`, `{"status":"cancelled"}` or
  `{"status":"error","code":…,"message":…}`. One `sign` at a time.
- How the sheet ends on an error, as on Android: at once, with no SDK
  message, when the gateway or the licence refuses (`blocked`, its message
  led by the gateway's code or `licence:`), the permission is withdrawn
  (`api_not_allowed`) or E-IMZO does not know the request's site
  (`invalid_request`); after the SDK has shown why and the user has dismissed
  it for an expired key (`key_expired`), E-IMZO refusing the signature
  (`sign_failed`, E-IMZO's words in `message`) or a blocked PIN
  (`sign_failed`, `pin_blocked`). Anything else stays in the sheet, and
  closing it then is `cancelled`.
- The PKCS#7 still goes from E-IMZO to your backend, never to the app.
- Error codes: `api_not_allowed`, `blocked`, `network`, `invalid_request`,
  `key_not_found`, `key_expired`, `busy`, `sign_failed` — the same on Android
  and in the Flutter plugin. The README's «Kalitlar API» section and
  INTEGRATION.md §11 have the details.

**Changed: the xcframework ships without dSYMs.** From 1.1.5 to 2.3 the
zip carried them. When you upload your app, Xcode may now say that the
archive has no dSYM for `EimzoSDK.framework`: that is expected, and the
upload goes through. Crashes that start in the SDK reach YT through its own
crash reports, and YT symbolicates them.

## 2.3.0 — 2026-11-06

**Read "Upgrading from 2.2" below before you update.** An app that is not
registered with the YT gateway gets the SDK's blocked screen, and
`from: "2.0.0"` or `from: "2.2.0"` resolves to 2.3.0 the next time packages
are updated.

The public API is `EImzoView`, `EImzoConfig` and `SignResult` as before,
plus `EImzoSignLink` and `EImzoEnvironment`; `EImzoConfig` gains
`environment` and `debugLogging`.

**New: every app signs through the YT gateway.** E-IMZO is reached only
through the gateway, which admits an app by App Attest: Apple vouches for its
bundle id and Team ID. To register, email `info@yt.uz` with the bundle id and
Team ID and say which environment: `dev` while you test, `prod` for release.
The two are registered separately. No licence file is needed.

App Attest needs a real iPhone or iPad; in the iOS Simulator the SDK shows
its blocked screen. That screen says in one sentence whether the app or the
device was refused, and keeps the technical reason, with the bundle id and a
copy button, under «Ishlab chiquvchi uchun».

**Apps that already ship a licence** (`EIMZO1.…`, from 2.0–2.2) open their
gateway session with the licence instead of App Attest. The SDK still checks
the licence on the device first, and the gateway must have it on record;
otherwise the blocked screen (`licence_not_registered`). Write to
`info@yt.uz` before you upgrade such an app, and keep 2.2 until YT confirms:
`.upToNextMinor(from: "2.2.0")`. The SDK no longer downloads the revocation
list (`revoked.txt` on GitLab Pages); the gateway refuses a revoked, expired
or unknown licence.

**Changed: `eimzo://` links are no longer taken from outside.** The scheme is
the E-IMZO app's, and an app that claims it opens its SDK for any page or app
that sends one. Take `eimzo` out of `CFBundleURLTypes` (the SDK logs a
warning when it finds it there) and drop the `onOpenURL` handler. Make the
request in the app from your backend's `siteId`, `documentId` and `hash`:
`EImzoSignLink.create(siteId:documentId:hash:)` returns the link for
`EImzoView(deepLink:)` and throws `EImzoSignLink.Error` on a malformed value.

**Changed: `environment` replaces `isTestMode`.** `EImzoConfig(environment:)`
takes `.prod`, the default — E-IMZO with real keys — or `.dev`, YT's test
environment on test.e-imzo.uz, where only test keys sign. The SDK knows both
environments' gateways; there is no address to configure. `isTestMode` still
works (`true` is `.dev`) and is deprecated.

**New: error and crash reports go to the YT gateway.** Always on, with no
switch.

- Sent: the action (adding a key, signing, scanning a QR, deleting a key), an
  error code, the message the user was shown, the kind of key, the SDK and
  iOS versions, the device model, and for a crash its stack.
- Never sent: names, PINFL/STIR, certificate serials, passwords, PINs, QR
  codes, documents or their hashes. They are scrubbed before a report leaves
  the phone.
- Only crashes that start in the SDK are reported, on the next start; the
  app's own crash reporter still gets them.
- In App Store Connect → App Privacy, declare **Crash Data** and **Other
  Diagnostic Data**: not linked to the user, not used for tracking, purpose
  App Functionality. The SDK ships a privacy manifest
  (`PrivacyInfo.xcprivacy`).

The gateway counts signatures per app and per kind of key — PFX file, QR
code, ID card, USB token, BAIK token. It never keeps what was signed or by
whom.

**New: the SDK's screens match the E-IMZO app.**

- Every sign request, made in the app or scanned, opens a confirmation
  screen first — domain, hash and key — and only its SIGN button signs.
  Signing waits for the site check.
- Errors read as plain sentences in a banner at the top; no exception, HTTP
  or gateway text reaches the screen.
- A new password sheet and PIN keypad; adding a key by file, QR, ID card, USB
  token or BAIK token from one list. A wrong PIN shows the attempts left, and
  a blocked ID card has its own sheet.
- Dynamic Type, enough contrast and VoiceOver labels. Screens stay inside the
  safe area with the phone turned sideways and with the keyboard up.
- The SDK's texts come in Uzbek, Russian and English, with the SDK's own
  language setting; the host app's language is left alone.

**Changed: after signing.** A request the app made ends on «Imzolandi» with
one «Ilovaga qaytish» (Return to the app) button. It returns by itself after
3 seconds and calls `onSignComplete`. «Saytga qaytish» and «Ilovada qolish»
are gone; in 2.2, «Ilovada qolish» left the app without its `SignResult`. A
request scanned from a QR code ends on «Tayyor», and the callback comes when
it is tapped (in 2.2 it came by itself after 1.8 seconds). `onSignComplete`
is called only with a signature E-IMZO accepted; errors stay on the SDK's
screen.

**Changed: requests and keys.**

- With no key yet, a request waits on the home screen and opens as soon as
  the first key is added. The 103-second countdown is gone: the server says
  when a request has expired.
- A key remembers the environment it was added in. In the other one it stays
  in the list, marked «Boshqa server», and cannot sign. Keys added before 2.3
  have no mark and sign in both.

**Fixed: ID cards and USB tokens.**

- The holder's name reads correctly, and the key shows its real expiry date
  and the holder's PINFL (JSHSHIR). Before, the date was misread (04.06.2028
  became "2026.20.28"), which also kept an expired key from being caught, and
  the PINFL was not read. Such keys added before 2.3 keep the old values:
  re-add them to correct.
- A card or token other than the chosen key's is caught before its PIN is
  sent.
- An ID card that does not come within Core NFC's minute fails with
  `card_timeout`. A USB token silent for 20 seconds fails with
  `token_timeout`, and a token no longer hangs on the next signature.

**New: `debugLogging`.** `EImzoConfig(debugLogging: true)` prints the SDK's
steps to the console — never keys, passwords, PINs or signatures. Off by
default; keep it off in release builds. Errors and warnings are printed
either way.

### Upgrading from 2.2

1. Register the app: email `info@yt.uz` the bundle id and Team ID
   (`codesign -dvvv MyApp.app 2>&1 | grep TeamIdentifier`) for `dev` and/or
   `prod`. Until it is registered the SDK shows its blocked screen, so do
   this before you test — on a real device.
2. If the app ships a licence, write to `info@yt.uz` first and stay on 2.2
   (`.upToNextMinor(from: "2.2.0")`) until YT confirms.
3. Remove `eimzo` from `CFBundleURLTypes` and the `eimzo://` `onOpenURL`
   handler; make sign requests with `EImzoSignLink.create`.
4. Replace `EImzoConfig(isTestMode:)` with `EImzoConfig(environment:)`.
5. Close the SDK's sheet in `onSignComplete`; it comes after «Ilovaga
   qaytish» (or 3 seconds) or «Tayyor».
6. Declare Crash Data and Other Diagnostic Data in App Privacy.
7. Update the package: `from: "2.3.0"`.

If you tried a 2.3.0-dev build: `testGatewayUrl` and `productionGatewayUrl`
are gone — `environment` replaces both.

## 2.2.0 — 2026-09-24

**New: BAIK USB tokens.** A key can now be added from a BAIK token and used to sign.

## 2.1.2 — 2026-08-27

**Fix: `EImzoConfig` could be silently discarded.**

`checkLicenseAndInit` overwrote the configured licence unconditionally. The
SDK's own screens re-init with a default config on every presentation, and
that config carries no licence — so a token passed at startup survived
exactly until the UI opened, and the app was then told "Litsenziya topilmadi"
with the licence sitting in the integrator's own config. It is now only
written when one was given.

**Better: "Litsenziya topilmadi" says what to do about it.**

The usual cause is not a missing licence but a file that never reached the
bundle: Xcode shows it in the navigator while leaving it out of *Copy Bundle
Resources*, and the app looks identical either way. The message now reports
what the bundle actually contains, and points at `EImzoConfig(license:)` as
the other way in.

Also: the settings screen was still reporting `Versiya 2.0.0`.

## 2.1.0 — 2026-08-26

**BREAKING, despite the minor version.** The public API is now just the
UI entry point.

A change like this normally takes a major bump. Minor was chosen because
nothing outside the SDK calls these symbols — they were never documented.

Three declarations remain public: `EImzoView`, `EImzoConfig` and `SignResult`.
Everything else — `KeyStore`, `EImzoSigner`, `EImzoApiClient`, `PkiUtils`,
`HexUtils`, `TokenSession`, `EImzoApplet`, the models — is internal. That is
141 public declarations outside the UI reduced to three.

None of it was ever documented; the README has always shown `EImzoView`. Now
the binary interface says the same thing: only public symbols reach an
xcframework's generated interface, so this is a real boundary rather than a
convention.

### Why

The signing flow spans the licence check, the PIN prompt, the session
deadline and the backend round-trip. Exposing its pieces let every integrator
rebuild that sequence — and rebuild it wrong.

### Migration

If you present `EImzoView`, nothing changes:

```swift
EImzoView(deepLink: link, onSignComplete: { _ in showEimzo = false })
```

If you were calling the internals directly, write to `info@yt.uz` and we will
work out what you need.

## 2.0.0 — 2026-08-25

**BREAKING: a licence is now required.**

The Firestore registration check is gone. The SDK verifies a signed offline
licence and nothing else — an app without one is refused, with no fallback.

Already-shipped apps are unaffected; they keep running on the SDK version they
were built with. The change bites when you upgrade.

### Migration

1. Email `info@yt.uz` with your Team ID:
   `codesign -dvvv MyApp.app 2>&1 | grep TeamIdentifier`
2. Add the returned file to your app bundle as `eimzo-license.txt`, or pass
   its text via `EImzoConfig(license:)`.
3. Update to 2.0.0.

The licence binds your bundle id **and** your team identifier, so it does not
work in another app.

### Also

- New design system: dark mode, uz/ru/en, Montserrat, selectable wallpapers,
  11 reworked screens.
- Live USB-token detection; the token can now be saved as a key.
- The settings screen reports the SDK's version rather than the host app's.
- The in-app "request access" form is gone — `info@yt.uz` instead.

## [1.1.7] - 2026-06-29

### Change: test API endpoint yangilandi

Test rejimi endpointi `https://m.test.e-imzo.uz/api/rpc` dan
`https://test.e-imzo.uz/api/rpc` ga o'zgartirildi (`m.` subdomeni
olib tashlandi). `EImzoConfig.testApiUrl` default qiymati yangilandi;
ilovangizda URL'ni qo'lda override qilayotgan bo'lsangiz, yangilang.
Production endpointi (`m.e-imzo.uz`) o'zgarmadi.

## [1.1.6] - 2026-06-11

### Feature: muddati tugagan sertifikat orqali imzolash bloklandi

Muddati o'tgan (`validTo` sanasi kelib o'tgan) sertifikat bilan endi
imzolab bo'lmaydi:

- **KeyCard** — muddati tugagan kartochka kulrang ko'rinishga o'tadi,
  qizil **"Muddati tugagan"** badge + qizil sana ko'rsatiladi.
- **IMZOLASH tugmasi** o'chiriladi + "Bu sertifikat muddati tugagan.
  Imzolash uchun yangi kalit qo'shing." matni chiqadi.
- **SDK-core guard** — `EImzoSigner` license check'dan keyin
  `isExpired()` tekshiradi va `SignError.certExpired` tashlaydi
  (deeplink, QR, auto-sign — barcha yo'llar qamralgan).
- Muddat tekshiruvi `validTo` sanasini real vaqt bilan (Asia/Tashkent)
  solishtiradi — server'dan kelgan muzlatilgan `validNow` bayrog'iga
  emas.

### Improvement: kalitni bir bosishda tanlash

Kalitlar ro'yxatida kartochka ustiga bir marta bosish endi uni darhol
faol (default) kalit qilib tanlaydi va Home sahifasiga qaytaradi.
Avvalgi "uzoq bosish → Default qilish" oqimi olib tashlandi. O'chirish
hanuz context menu (uzoq bosish) orqali.

### Checksums

- **EimzoSDK:** `200ca39198ef8fa28e23c7e7eb19d27cbb08b4a739c5b03ae6a2337a4a94148e`
- **Pfx2qr:**  `eb26550edc4c46158249f1240997458cc3390eef75cd54e8db0165491e15538f`

## [1.1.5] - 2026-06-10

### Fix: App Store nested framework rejection + dSYM

1.1.4 va undan oldingi versiyalarda `Pfx2qr.framework` `EimzoSDK.framework/Frameworks/`
ichiga embed qilingan edi. App Store Connect bunday tuzilmani qabul qilmaydi:

```
ITMS-90205  contains disallowed nested bundles
ITMS-90206  contains disallowed file 'Frameworks'
ITMS-90035  inner Pfx2qr Mach-O not properly signed
```

Va `dSYM` yo'qligi haqida warning chiqar edi.

**Yechim — 1.1.5:**

- `Pfx2qr.xcframework` endi alohida release artifact:
  - `EimzoSDK.xcframework.zip` (17 MB)
  - `Pfx2qr.xcframework.zip` (7.3 MB)
- `Package.swift` ikkita `.binaryTarget` declare qiladi (`EimzoSDK` +
  `Pfx2qr`), ikkalasi bir library product ichida — Xcode ularni
  `App.app/Frameworks/` ostiga **yonma-yon** joylashtiradi.
- `dSYM` fayllari `xcframework/<arch>/dSYMs/` ichida ship qilinadi.
  App Store endi crash log'larni to'liq symbolicate qiladi.

### Breaking change (consumer side)

Integratorlar `pod install` / `swift package resolve` ni qaytadan
ishga tushirishlari kerak — public API o'zgargani yo'q.

### Checksums

- **EimzoSDK:** `b7982b9fbcd3c9e9e7eddb85fbeaba1f5804d6056b500d7433ab6c4517611e6b`
- **Pfx2qr:**  `1a0cde63c01b7d11c971d713cd3c106135f495731827b113049630ea7fa099bc`

## [1.1.4] - 2026-06-09

### Feature: 103-soniyalik deeplink sessiyasi

Deeplink orqali ochilgan imzo so'rovi endi **darhol** imzolanmaydi —
SDK 103 soniyalik sessiya ochadi va foydalanuvchi shu vaqt davomida:

- Yangi kalit qo'shishi (ID karta, PFX, QR yoki USB token),
- yoki mavjud kalitni tanlashi,
- **IMZOLASH** tugmasini bosib imzolashi mumkin.

`HomeView` yuqorisida live countdown banner ko'rinadi (mm:ss + progress
bar; 15 soniya qolganda qizilga o'tadi). Vaqt tugasa "Sessiya muddati
tugadi" overlay chiqadi.

**Sabab:** integratorlar deeplink kelishi bilan SDK avtomatik
imzolashga o'tib ketardi — agar kalit hali yo'q bo'lsa foydalanuvchi
nima imzolashini ko'ra olmasdan kalit qo'shishga majbur edi. Yangi
oqim: deeplink → 103s window → kalit qo'shish (zarur bo'lsa) →
IMZOLASH.

**API o'zgarishi yo'q** — `EImzoView(deepLink:)` xuddi avvalgidek
ishlatiladi.

### XCFramework

- **size:** 6.3 MB
- **checksum (SHA-256):** `09f969174630f7f28a600e61bd0f592e564fdad3db7493ee8d4b4d69fc03ffe0`

## [1.1.3] - 2026-06-08

### Fix: HomeView'da orqaga qaytish tugmasi

EImzoView sheet sifatida ochilganda foydalanuvchi HomeView'dan SDK'ni
yopib chiqib keta olmas edi. Top-leading hamburger icon funksiyasiz edi —
endi `chevron.backward` orqaga tugmasi bilan almashtirildi va
`@Environment(\.dismiss)` orqali sheet'ni yopadi.


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
