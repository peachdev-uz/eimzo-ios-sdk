# Changelog

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
