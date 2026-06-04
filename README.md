# EimzoSDK for iOS

E-IMZO mobil imzolash SDK'si iOS uchun. SwiftUI-based, native crypto (OzDST 1092 / 1106 / GOST 28147), NFC ID karta + QR + PFX qo'llab-quvvatlash.

- **iOS 16+** • **Swift 5.9+** • **SwiftUI**
- Hammasi bir SwiftUI view'da: `EImzoView`. Host'ingiz uni sheet sifatida present qiladi va imzo natijasini callback orqali oladi.

## O'rnatish

### Swift Package Manager

`File → Add Package Dependencies…` orqali:

```
https://github.com/peachdev-uz/eimzo-ios-sdk
```

Yoki `Package.swift`'ga qo'lda qo'shing:

```swift
dependencies: [
    .package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "1.0.0"),
],
targets: [
    .target(name: "YourApp", dependencies: ["EimzoSDK"]),
]
```

### Manual installation

Releases sahifasidan `EimzoSDK.xcframework`'ni yuklab oling va Xcode → **Frameworks, Libraries, and Embedded Content** ostiga **Embed & Sign** rejimida qo'shing.

## Talablar

### Bundle identifier ro'yxatdan o'tkazish

SDK ilovangiz bundle ID'sini server'da ro'yxatdan o'tkazgan bo'lishini talab qiladi. **Ro'yxatdan o'tish uchun** `info@peachdev.uz`'ga quyidagilarni yuboring:

1. Bundle ID (masalan `uz.peachdev.app`)
2. Ilova nomi va qisqacha tavsifi
3. Kontakt ma'lumotlari (kompaniya, email, telefon)

Tasdiqlangandan keyin SDK ishlay boshlaydi. SDK'ni sinash uchun ham bundle ID kerak.

### Info.plist + Entitlements

#### Camera (QR scanner uchun)

```xml
<key>NSCameraUsageDescription</key>
<string>QR-kod o'qish uchun kamera kerak</string>
```

#### NFC (ID karta uchun)

`*.entitlements`:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array><string>TAG</string></array>
```

`Info.plist`:

```xml
<key>NFCReaderUsageDescription</key>
<string>ID-karta orqali kalit o'qish uchun NFC kerak</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>65696D7A6F617070</string>  <!-- "eimzoapp" ASCII -->
</array>
```

NFC entitlement Apple Developer hisobida qo'lda yoqilishi kerak (bir martalik tasdiqlash).

## Foydalanish

### Asosiy holat

```swift
import SwiftUI
import EimzoSDK

struct ContentView: View {
    @State private var showEimzo = false
    @State private var deepLink: String?

    var body: some View {
        Button("Imzolash") {
            showEimzo = true
        }
        .sheet(isPresented: $showEimzo) {
            EImzoView(
                deepLink: deepLink,
                onSignComplete: { result in
                    // result — .success(state, message, serialNumber, signature)
                    // yoki .failure(message). SDK avtomatik 1.5s'dan keyin
                    // o'zini yopadi; bu yerda host sheet'ni yopishi kerak.
                    showEimzo = false
                }
            )
        }
    }
}
```

### Deeplink orqali ochish

Boshqa ilovadan kelgan `eimzo://sign?qc=...` deeplink'ini ushlab olib, SDK'ga uzating:

```swift
@main
struct MyApp: App {
    @State private var incomingDeepLink: String?

    var body: some Scene {
        WindowGroup {
            ContentView(incomingDeepLink: $incomingDeepLink)
                .onOpenURL { url in
                    guard url.scheme == "eimzo" else { return }
                    incomingDeepLink = url.absoluteString
                }
        }
    }
}
```

### Test rejimi

QA stenddagi imzolashlar uchun:

```swift
EImzoView(
    config: EImzoConfig(isTestMode: true),  // m.test.e-imzo.uz
    deepLink: deepLink,
    onSignComplete: { _ in }
)
```

## SDK qanday ishlaydi?

1. **License check** — Bundle ID Firestore'da `allowed_integrators` collection'ida bormi tekshiriladi
2. **Home page** — saqlangan kalitlar ro'yxati, IMZOLASH tugmasi
3. **Cards page** — kalit qo'shish (PFX fayl / QR / NFC)
4. **Sign flow** — deeplink kelganda yoki IMZOLASH bosilganda:
   - Domain + hash tasdiqlash dialog
   - Parol so'rash (saqlangan bo'lsa, avtomatik)
   - OzDST 1092 imzo + `pki.send_pkcs7`
   - IMZOLANDI overlay → host'ga callback

## Foydalanish misoli

To'liq ishlaydigan namuna repo'da: [`EimzoExample.xcodeproj`](EimzoExample.xcodeproj) — Xcode'da oching, **Signing & Capabilities** ostida o'z Apple ID jamoangizni tanlang, **Cmd+R** bilan ishga tushiring.

```bash
git clone https://github.com/peachdev-uz/eimzo-ios-sdk
cd eimzo-ios-sdk
open EimzoExample.xcodeproj
```

Demo ilova quyidagini namoyish qiladi:
- `EImzoView` ni sheet sifatida ochish
- Test rejimi (`m.test.e-imzo.uz`) toggle
- `eimzo://sign?qc=...` deeplink'larini `onOpenURL`'da ushlash
- `onSignComplete` callback orqali natijani olish

## Documentation

- [INTEGRATION.md](docs/INTEGRATION.md) — to'liq integratsiya qo'llanma
- [MANUAL_INSTALLATION.md](docs/MANUAL_INSTALLATION.md) — SPM'siz Xcode'ga qo'lda qo'shish

## Versiya tarixi

[CHANGELOG.md](CHANGELOG.md)

## Litsenziya

Closed-source. Foydalanish uchun `info@peachdev.uz` orqali bog'laning.
