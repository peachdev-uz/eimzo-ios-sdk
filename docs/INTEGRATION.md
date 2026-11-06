# Integration guide

## 1. Ro'yxatdan o'tish

SDK E-IMZO bilan faqat YT gateway orqali ishlaydi. Gateway ilovani App Attest
bilan taniydi: Apple ilovaning bundle ID'si va Team ID'sini tasdiqlaydi.
Litsenziya fayli kerak emas — ilova gateway'da ro'yxatdan o'tkaziladi.

Ro'yxatdan o'tish: `info@yt.uz`'ga yuboring:

- Bundle ID (`Info.plist` → `CFBundleIdentifier`)
- Team ID: `codesign -dvvv YourApp.app 2>&1 | grep TeamIdentifier`
- Muhit: `dev` (sinov, `EImzoConfig(environment: .dev)`) va/yoki `prod`
  (chiqariladigan ilova, `.prod`). Ular alohida ro'yxatdan o'tkaziladi
  (6-bo'lim).
- Ilova nomi, kompaniya ma'lumoti, kontakt: email, telefon

Bundle ID'si boshqa bo'lgan build (masalan `….dev`) alohida ilova
hisoblanadi — uni ham yuboring.

SDK ochilishi bilan gateway ilovani tekshiradi. Ilova ro'yxatda bo'lmasa yoki
unga ruxsat to'xtatilgan bo'lsa, SDK bloklangan ekranni ko'rsatadi va
imzolash ishlamaydi. Texnik sabab ekrandagi «Ishlab chiquvchi uchun»
bo'limida, bundle ID bilan birga (masalan `gateway app_not_registered: …`).

App Attest faqat haqiqiy iPhone yoki iPad'da ishlaydi: iOS Simulator'da SDK
bloklangan ekranni ko'rsatadi. SDK'ni qurilmada sinang.

### Ilovada litsenziya bo'lsa (2.0–2.2)

2.0–2.2 dagi litsenziya (`EIMZO1.…`: `eimzo-license.txt` resursi yoki
`EImzoConfig(license:)`) bilan ishlayotgan ilova 2.3 da ham shu litsenziya
bilan ishlaydi: SDK uni qurilmada tekshiradi, keyin gateway sessiyasini App
Attest o'rniga litsenziya bilan ochadi. Litsenziya gateway'da qayd etilgan
bo'lishi kerak, aks holda bloklangan ekran chiqadi (`licence_not_registered`).
Bunday ilovani 2.3 ga o'tkazishdan oldin `info@yt.uz`'ga yozing va YT
tasdiqlaguncha 2.2 da qoling:

```swift
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", .upToNextMinor(from: "2.2.0"))
```

(`from: "2.2.0"` paketlar yangilanganda 2.3.0 ni ham oladi.)

Bekor qilingan, muddati o'tgan yoki gateway bilmaydigan litsenziyani gateway
rad etadi. Bekor qilingan litsenziyalar ro'yxatini (`revoked.txt`) SDK endi
o'zi yuklab olmaydi.

Yangi ilova uchun litsenziya kerak emas — yuqoridagidek ro'yxatdan o'ting.

## 2. Loyihaga qo'shish

### SPM (tavsiya etiladi)

Xcode → File → Add Package Dependencies → URL:
```
https://github.com/peachdev-uz/eimzo-ios-sdk
```

Version rule: **Up to Next Major Version** dan **2.3.0**. Product:
`EimzoSDK`.

`Package.swift`da:

```swift
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "2.3.0")
// target'da:
.product(name: "EimzoSDK", package: "eimzo-ios-sdk")
```

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

`eimzo` URL sxemasini `CFBundleURLTypes`ga qo'shmang (5-bo'lim).

## 4. Asosiy foydalanish

```swift
import SwiftUI
import EimzoSDK

/// SDK nima bilan ochiladi: imzo so'rovi (5-bo'lim) bilan yoki usiz.
struct EImzoRequest: Identifiable {
    let id = UUID()
    let link: String?   // nil — SDK bosh sahifasi
}

struct ContentView: View {
    @State private var request: EImzoRequest?

    var body: some View {
        Button("E-IMZO ochish") { request = EImzoRequest(link: nil) }
            .sheet(item: $request) { shown in
                EImzoView(
                    config: EImzoConfig(environment: .prod),
                    deepLink: shown.link,
                    onSignComplete: { result in
                        if case .success(_, _, let serialNumber, let signature) = result {
                            // signature — 128 belgili hex
                            // serialNumber — sertifikat seriya raqami
                        }
                        request = nil   // SDK o'zini yopmaydi
                    }
                )
            }
    }
}
```

`sheet(item:)` ishlating: `sheet(isPresented:)` va alohida `@State` havola
bilan sheet havola yangilanishidan oldin ochilib, SDK so'rovsiz ochilishi
mumkin.

## 5. Imzo so'rovi — faqat ilova ichidan

`eimzo://` sxemasi E-IMZO ilovasiniki. Ilovangiz uni ro'yxatdan o'tkazmaydi
(`Info.plist`dagi `CFBundleURLTypes`ga qo'shmang, `onOpenURL` bilan
ushlamang): aks holda istalgan sayt yoki ilova sizning SDK'ingizni imzo
so'rovi bilan ochishi mumkin bo'lardi. SDK host `Info.plist`ida `eimzo`
sxemasini topsa, logga ogohlantirish yozadi. 2.2 dan o'tayotgan bo'lsangiz,
`eimzo` sxemasini va uning `onOpenURL` ishlovchisini olib tashlang.

So'rov ilova ichida yasaladi: hujjatning `siteId`, `documentId` va `hash`
qiymatlari sizning backend'ingizdan keladi, havolani SDK yasaydi va CRC32 ni
qo'shadi:

```swift
do {
    let link = try EImzoSignLink.create(siteId: siteId, documentId: documentId, hash: hash)
    request = EImzoRequest(link: link)
} catch {
    // EImzoSignLink.Error: qiymat formati noto'g'ri (siteId 4, documentId
    // 8, 10, 12, 14 yoki 16, hash 64 hex belgi)
}
```

`EImzoView(deepLink:)` so'rovni avval ko'rsatadi (domen, hesh, kalit) va
foydalanuvchi IMZOLASH'ni bosgandagina imzolaydi. Kalit hali bo'lmasa, so'rov
bosh sahifada kutadi va birinchi kalit qo'shilishi bilan ochiladi. So'rov
muddati tugaganini server aytadi.

## 6. Muhit: prod yoki dev

YT test muhiti (`test.e-imzo.uz`) bilan ishlash uchun:

```swift
EImzoView(
    config: EImzoConfig(environment: .dev),
    ...
)
```

`.prod` (sukut bo'yicha) — haqiqiy E-IMZO, `.dev` — test muhiti, u yerda faqat
test kalitlari imzolaydi. Manzil berilmaydi: SDK har bir muhitning YT
gateway manzilini o'zi biladi. Ilova E-IMZO bilan shu gateway orqali
ishlaydi — litsenziyali bo'lsa ham, litsenziyasiz bo'lsa ham. Ilova tanlangan
muhitda ro'yxatdan o'tgan bo'lishi kerak (1-bo'lim).

Production imzo so'rovlarini test muhitida imzolab bo'lmaydi va aksincha —
ikkala serverda hujjatlar bazasi alohida.

Kalit qaysi muhitda qo'shilganini eslab qoladi. Boshqa muhitda u ro'yxatda
qoladi, lekin «Boshqa server» deb belgilanadi va u bilan imzolab bo'lmaydi.
2.3 dan oldin qo'shilgan kalitlarda belgi yo'q — ular ikkala muhitda ham
ishlaydi.

2.2 dagi `isTestMode` hali ishlaydi (`true` — `.dev`), lekin eskirgan.

## 7. Callbacks

```swift
EImzoView(
    deepLink: link,
    onSignComplete: { result in
        switch result {
        case .success(let state, let message, let serial, let signature):
            // signature — 128 char hex (s||r)
            // serial — cert serial number
            // state, message — E-IMZO javobi
        case .failure:
            // EImzoView bu yerga xato yubormaydi: xatolarni o'zi ko'rsatadi
            break
        @unknown default:
            break
        }
    }
)
```

`@unknown default` kerak: SDK binar framework, `SignResult` esa kelajakda
yangi holat olishi mumkin bo'lgan enum. Usiz Swift 6 rejimida `switch`
xato beradi.

`onSignComplete` E-IMZO imzoni qabul qilgandan keyin chaqiriladi:

- ilova bergan so'rovda — «Imzolandi» ekranidagi «Ilovaga qaytish» bosilganda
  yoki taxminan 3 soniyadan keyin o'zi;
- QR koddan skanerlangan so'rovda — «Tayyor» bosilganda.

SDK o'zini yopmaydi: sheet'ni callback'da yoping. Xatolar (noto'g'ri parol
yoki PIN, tarmoq, server rad etishi) SDK ekranidagi bannerda ko'rsatiladi va
foydalanuvchi qayta urinadi. Foydalanuvchi SDK'ni imzolamasdan yopsa, callback
chaqirilmaydi — kerak bo'lsa, buni `sheet`ning `onDismiss`ida biling.

## 8. Debug log

```swift
EImzoConfig(environment: .dev, debugLogging: true)
```

SDK qadamlari (chaqiruvlar, holatlar) Xcode konsoliga yoziladi. Kalit,
parol, PIN, imzo, hesh va imzo havolasi yozilmaydi. Sukut bo'yicha o'chiq;
release build'da yoqmang. Xatolar va ogohlantirishlar (masalan, `eimzo`
sxemasi topilganda) har doim yoziladi.

## 9. Xato va crash hisobotlari

SDK foydalanuvchi duch kelgan xatolar va SDK ichida boshlangan crash'lar
haqida YT gateway'iga hisobot yuboradi; bu o'chirilmaydi. Nima yuborilishi va
nima yuborilmasligi — [README](../README.md#xato-va-crash-hisobotlari)da.

App Store Connect → App Privacy'da **Crash Data** va **Other Diagnostic
Data**ni e'lon qiling: Not Linked to You, Not Used for Tracking, maqsadi
App Functionality. SDK o'zining privacy manifest'i (`PrivacyInfo.xcprivacy`)
bilan keladi.

## 10. Versiya yangilash

CHANGELOG.md'ni har release oldidan ko'ring — integratsiyani o'zgartiradigan
narsa bo'lsa, shu yerda yoziladi. Bu minor versiyada ham bo'lishi mumkin:
2.3.0 dan ilova ro'yxatdan o'tgan bo'lishi kerak.

```
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "2.3.0")
```

`from: "2.3.0"` semantic versioning bo'yicha 2.3.0 va undan yangi 2.x
versiyalarni qabul qiladi, 3.0.0 ni olmaydi.
