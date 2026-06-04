# Integration guide

## 1. Bundle ID ro'yxatdan o'tkazish

SDK'ni ishlatishdan oldin **bundle ID'ingizni ro'yxatdan o'tkazish** kerak.

E'tibor: SDK har bir muhim operatsiya (sign / kalit qo'shish) oldidan
license check'ni o'tkazadi (30 daqiqalik kesh bilan). Bundle ID ro'yxatda
bo'lmasa, SDK BlockedView'ni ko'rsatadi va imzolash ishlamaydi.

Ro'yxatdan o'tish: `info@peachdev.uz`'ga yuboring:

- Bundle ID (`Info.plist` → `CFBundleIdentifier`)
- Ilova nomi
- Kompaniya ma'lumoti
- Kontakt: email, telefon

Test va production uchun **alohida** bundle ID'lar tavsiya etiladi.

## 2. Loyihaga qo'shish

### SPM (tavsiya etiladi)

Xcode → File → Add Package Dependencies → URL:
```
https://github.com/peachdev-uz/eimzo-ios-sdk
```

Version rule: **Up to Next Major Version** dan **1.0.0**.

### Manual

[MANUAL_INSTALLATION.md](MANUAL_INSTALLATION.md)'ga qarang.

## 3. Permissions

### Camera (QR scanner)

`Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>QR-kod o'qish uchun kamera kerak</string>
```

### NFC (ID karta)

Apple Developer'da bir martalik NFC entitlement so'rang. Tasdiqlangandan keyin
`*.entitlements`'da:

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
  <string>65696D7A6F617070</string>
</array>
```

## 4. Asosiy foydalanish

```swift
import SwiftUI
import EimzoSDK

struct ContentView: View {
    @State private var showSdk = false
    @Binding var incomingDeepLink: String?

    var body: some View {
        Button("E-IMZO ochish") { showSdk = true }
            .sheet(isPresented: $showSdk) {
                EImzoView(
                    config: EImzoConfig(isTestMode: false),
                    deepLink: incomingDeepLink,
                    onSignComplete: { result in
                        if result.isSuccess {
                            // result.signature — 128 char hex
                            // result.serialNumber — sertifikat seriya raqami
                        }
                        showSdk = false
                        incomingDeepLink = nil
                    }
                )
            }
    }
}
```

## 5. Deeplink handling

Boshqa ilova `eimzo://sign?qc=...` deeplink yuborganda:

```swift
@main
struct MyApp: App {
    @State var incomingDeepLink: String?
    var body: some Scene {
        WindowGroup {
            ContentView(incomingDeepLink: $incomingDeepLink)
                .onOpenURL { url in
                    if url.scheme == "eimzo" {
                        incomingDeepLink = url.absoluteString
                    }
                }
        }
    }
}
```

ContentView'da `incomingDeepLink` o'zgarganda SDK sheet'ni avtomatik ochib,
sign flow'ga kiradi (`EImzoView(deepLink:)` orqali).

## 6. Test rejimi

`m.test.e-imzo.uz` (QA stand) bilan ishlash uchun:

```swift
EImzoView(
    config: EImzoConfig(isTestMode: true),
    ...
)
```

Production deeplinklarini test rejimida sinab bo'lmaydi va aksincha — har
ikkala serverda doc DB alohida.

## 7. Callbacks

```swift
EImzoView(
    deepLink: link,
    onSignComplete: { result in
        switch result {
        case .success(let state, let message, let serial, let signature):
            // signature — 128 char hex (s||r)
            // serial — cert serial number
        case .failure(let message):
            // server xato yoki user bekor qildi
        }
    }
)
```

## 8. Versiya yangilash

CHANGELOG.md'ni har release oldidan ko'ring — breaking changes bo'lsa
shu yerda yoziladi.

```
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "1.0.0")
```

`from: "1.0.0"` semantic versioning bo'yicha 2.0.0 dan oldingi har qanday
versiyani qabul qiladi.
