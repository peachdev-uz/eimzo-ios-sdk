# EimzoSDK for iOS

E-IMZO mobil imzolash SDK'si iOS uchun. SwiftUI-based, native crypto (OzDST 1092 / 1106 / GOST 28147). Kalitlar: PFX fayl, QR, ID karta (NFC), USB token, BAIK token.

- **iOS 16+** • **Swift 5.9+** • **SwiftUI**
- Hammasi bir SwiftUI view'da: `EImzoView`. Host'ingiz uni sheet sifatida present qiladi va imzo natijasini callback orqali oladi.
- 2.4.0 dan, ruxsat berilgan integrator uchun: kalitlar ro'yxati va SDK oynasi orqali imzo — `EImzoAPI` (pastda «Kalitlar API»).
- SDK E-IMZO bilan YT gateway orqali ishlaydi, shuning uchun ilovangiz ro'yxatdan o'tgan bo'lishi kerak (pastda «Ro'yxatdan o'tish»).

## O'rnatish

### Swift Package Manager

`File → Add Package Dependencies…` orqali:

```
https://github.com/peachdev-uz/eimzo-ios-sdk
```

Dependency Rule: **Up to Next Major Version**, **2.4.1** dan.

Yoki `Package.swift`'ga qo'lda qo'shing:

```swift
dependencies: [
    .package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "2.4.1"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "EimzoSDK", package: "eimzo-ios-sdk"),
    ]),
]
```

### Manual installation

GitHub Releases'dagi `2.4.1` release'dan `EimzoSDK.xcframework.zip` va `Pfx2qr.xcframework.zip`'ni yuklab olib, Xcode'ga qo'shing: [MANUAL_INSTALLATION.md](docs/MANUAL_INSTALLATION.md).

## Talablar

### Ro'yxatdan o'tish

SDK E-IMZO bilan faqat YT gateway orqali ishlaydi. Gateway ilovangizni App Attest bilan taniydi: Apple ilovaning bundle ID'si va Team ID'sini tasdiqlaydi. Litsenziya fayli kerak emas.

Ro'yxatdan o'tish uchun `info@yt.uz`'ga quyidagilarni yuboring:

1. Bundle ID (masalan `uz.example.app`)
2. Team ID: `codesign -dvvv YourApp.app 2>&1 | grep TeamIdentifier`
3. Muhit: `dev` — sinov uchun (`EImzoConfig(environment: .dev)`), `prod` — chiqariladigan ilova uchun (`.prod`, haqiqiy E-IMZO). Ular alohida ro'yxatdan o'tkaziladi; ikkalasi kerak bo'lsa, ikkalasini yozing.
4. Ilova nomi va kontakt ma'lumotlari (kompaniya, email, telefon)

Bundle ID'si boshqa bo'lgan build (masalan `uz.example.app.dev`) alohida ilova hisoblanadi — uni ham yuboring.

Ro'yxatdan o'tmagan ilovada SDK bloklangan ekranni ko'rsatadi va imzolab bo'lmaydi. Texnik sababi shu ekranning «Ishlab chiquvchi uchun» bo'limida (masalan `app_not_registered`).

App Attest faqat haqiqiy iPhone yoki iPad'da ishlaydi. iOS Simulator attestatsiya qila olmaydi, u yerda SDK bloklangan ekranni ko'rsatadi — SDK'ni qurilmada sinang.

#### Ilovangizda litsenziya bo'lsa

2.0–2.2 dagi litsenziya (`EIMZO1.…`: `eimzo-license.txt` fayli yoki `EImzoConfig(license:)`) bilan ishlayotgan ilova 2.3 da gateway sessiyasini App Attest o'rniga shu litsenziya bilan ochadi. Litsenziya gateway'da qayd etilgan bo'lishi kerak, aks holda bloklangan ekran chiqadi. Shuning uchun bunday ilovani 2.3 ga o'tkazishdan oldin `info@yt.uz`'ga yozing va YT tasdiqlaguncha 2.2 da qoling. `from: "2.2.0"` paketlar yangilanganda 2.3.0 ni ham oladi; 2.2 da qolish uchun `.upToNextMinor(from: "2.2.0")` yozing.

Bekor qilingan, muddati o'tgan yoki gateway bilmaydigan litsenziyani gateway rad etadi. Bekor qilingan litsenziyalar ro'yxatini (`revoked.txt`) SDK endi o'zi yuklab olmaydi.

Yangi ilova uchun litsenziya kerak emas — yuqoridagidek ro'yxatdan o'ting.

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

`eimzo` URL sxemasini `CFBundleURLTypes`ga **qo'shmang** — pastda «Imzo so'rovini ilova ichida yaratish»ga qarang.

## Foydalanish

### Asosiy holat

```swift
import SwiftUI
import EimzoSDK

/// SDK nima bilan ochiladi: imzo so'rovi bilan yoki usiz.
struct EImzoRequest: Identifiable {
    let id = UUID()
    let link: String?   // nil — SDK bosh sahifasi
}

struct ContentView: View {
    @State private var request: EImzoRequest?

    var body: some View {
        Button("E-IMZO") {
            request = EImzoRequest(link: nil)
        }
        .sheet(item: $request) { shown in
            EImzoView(
                deepLink: shown.link,
                onSignComplete: { result in
                    // E-IMZO qabul qilgan imzo:
                    // result — .success(state, message, serialNumber, signature).
                    // SDK o'zini yopmaydi: sheet'ni shu yerda yoping.
                    request = nil
                }
            )
        }
    }
}
```

`sheet(item:)` ishlating: `sheet(isPresented:)` va alohida `@State` havola bilan sheet havola yangilanishidan oldin ochilib, SDK so'rovsiz ochilishi mumkin.

`onSignComplete` faqat E-IMZO imzoni qabul qilgandan keyin chaqiriladi. Xatolarni (noto'g'ri parol yoki PIN, tarmoq) SDK o'z ekranida ko'rsatadi. Foydalanuvchi SDK'ni imzolamasdan yopsa, callback chaqirilmaydi.

### Imzo so'rovini ilova ichida yaratish

Ilovangiz `eimzo://` havolalarini tashqaridan **qabul qilmaydi**: bu sxema
E-IMZO ilovasiniki, uni `Info.plist`dagi `CFBundleURLTypes`ga qo'shmang (SDK
uni topsa logga ogohlantirish yozadi). Hujjatning `siteId`, `documentId` va
`hash` qiymatlarini o'z backend'ingizdan oling, havolani SDK yasaydi:

```swift
let link = try EImzoSignLink.create(
    siteId: siteId,          // 4 hex belgi
    documentId: documentId,  // 8, 10, 12, 14 yoki 16 hex belgi
    hash: hash               // 64 hex belgi
)
request = EImzoRequest(link: link)   // EImzoView(deepLink: shown.link, …)
```

Qiymat formati noto'g'ri bo'lsa, `create` `EImzoSignLink.Error` tashlaydi.

SDK avval so'rovni ko'rsatadi (domen, hesh, kalit), foydalanuvchi IMZOLASH'ni
bosgandagina imzolaydi. Kalit hali bo'lmasa, so'rov bosh sahifada kutadi va
birinchi kalit qo'shilishi bilan ochiladi. So'rov muddati tugaganini server
aytadi — telefonda hisoblagich yo'q.

### Imzodan keyin

Ilova bergan so'rov imzolangach, SDK «Imzolandi» ekranini bitta «Ilovaga
qaytish» tugmasi bilan ko'rsatadi. Tugma bosilganda — yoki taxminan 3
soniyadan keyin o'zi — SDK `onSignComplete`ni chaqiradi va ilovangiz sheet'ni
yopadi. QR koddan skanerlangan so'rov «Tayyor» tugmasi bilan tugaydi, callback
shu tugma bosilganda keladi.

### Muhit (`environment`)

`environment` SDK qaysi E-IMZO bilan ishlashini tanlaydi: `.prod` (sukut
bo'yicha) — haqiqiy E-IMZO, `.dev` — YT test muhiti (test.e-imzo.uz), u yerda
faqat test kalitlari imzolaydi. Boshqa hech narsa sozlanmaydi: SDK har bir
muhitning gateway manzilini o'zi biladi. Ilova tanlangan muhitda ro'yxatdan
o'tgan bo'lishi kerak.

Kalit qaysi muhitda qo'shilganini eslab qoladi. Boshqa muhitda u ro'yxatda
qoladi, lekin «Boshqa server» deb belgilanadi va u bilan imzolab bo'lmaydi.
2.3 dan oldin qo'shilgan kalitlarda belgi yo'q — ular ikkala muhitda ham
ishlaydi.

```swift
EImzoView(
    config: EImzoConfig(environment: .dev),  // test.e-imzo.uz
    deepLink: shown.link,
    onSignComplete: { _ in request = nil }
)
```

2.2 dagi `isTestMode` hali ishlaydi (`true` — `.dev`), lekin eskirgan.

### Debug log (`debugLogging`)

`EImzoConfig(debugLogging: true)` SDK qadamlarini Xcode konsoliga yozadi.
Kalit, parol, PIN va imzo yozilmaydi. Sukut bo'yicha o'chiq; release build'da
yoqmang. Xatolar va ogohlantirishlar har doim yoziladi.

## Kalitlar API

2.4.0 dan SDK'ning ikkita usuli bor: `EImzoAPI.getKeys` foydalanuvchi SDK'ga
qo'shgan kalitlar ro'yxatini beradi, `EImzoAPI.sign` esa ulardan biri bilan
SDK'ning o'z imzo oynasi orqali imzolaydi. Ikkalasi JSON (`String`) qaytaradi.

Kalitlar API faqat YT ruxsat bergan integratorda ishlaydi: ruxsatni
`info@yt.uz` orqali so'rang, u shartnomadan keyin beriladi va
integratorning barcha ilovalariga tegishli. Ruxsat bo'lmasa ikkala usul
`api_not_allowed` qaytaradi. Foydalanuvchi kalitlarini avvalgidek
`EImzoView`da qo'shadi.

```swift
let config = EImzoConfig(environment: .prod)

let keys = await EImzoAPI.getKeys(config: config)
// {"status":"ok","keys":[{"id":"7a3f…","pinfl":"31234567890123",
//   "name":"ALIYEV VALI ALIYEVICH","validFrom":"2025-03-01","validTo":"2027-03-01"}]}

let link = try EImzoSignLink.create(siteId: siteId, documentId: documentId, hash: hash)
let result = await EImzoAPI.sign(keyId: id, deepLink: link, config: config)
// {"status":"signed"} · {"status":"cancelled"} · {"status":"error","code":"…","message":"…"}
```

- Ro'yxatda faqat `id`, `pinfl` (yo'q bo'lsa `null`), `name`, `validFrom`,
  `validTo` (`yyyy-MM-dd`). Tanlangan muhitdagi barcha kalitlar, muddati
  o'tganlari ham; asosiy kalit birinchi. `id`ni o'zgartirmasdan `sign`ga
  bering.
- `sign` imzo oynasini ilovangizning eng ustki ekrani ustida ochadi: domen,
  hesh va siz tanlagan kalit. Foydalanuvchi IMZOLASH'ni bosadi, parol yoki
  PIN faqat shu oynada kiritiladi. Imzodan keyin «Imzolandi» 3 soniyada o'zi
  yopiladi. Bir vaqtda bitta `sign`.
- Kalit muddati tugasa, E-IMZO imzoni rad etsa yoki PIN bloklansa, SDK
  sababini oynada ko'rsatadi va foydalanuvchi uni yopgach xato qaytaradi.
  Foydalanuvchi tuzatsa bo'ladigan xatodan (noto'g'ri parol, internet yo'q)
  keyin oyna yopilsa — `cancelled`.
- Imzolangan hujjat ilovaga qaytmaydi: E-IMZO uni avvalgidek backend'ingizga
  yuboradi.

| `code` | Qachon |
|---|---|
| `api_not_allowed` | «Kalitlar API» ruxsati yo'q yoki o'chirilgan |
| `blocked` | litsenziya tekshiruvi yoki gateway ilovani yoki qurilmani rad etdi; `message` kod bilan boshlanadi (`app_blocked: …`, `licence: …`) |
| `network` | gateway'ga ulanib bo'lmadi yoki javob kelmadi |
| `invalid_request` | `deepLink` imzo so'rovi emas yoki uning sayti E-IMZO'da ro'yxatdan o'tmagan |
| `key_not_found` | bu `id` bilan shu muhitda kalit yo'q |
| `key_expired` | kalit sertifikati muddati tugagan |
| `busy` | boshqa `sign` hali ochiq |
| `sign_failed` | E-IMZO imzoni rad etdi, PIN bloklandi (`message`: `pin_blocked`) yoki oqim boshqa xato bilan tugadi |

To'liq tavsif: [INTEGRATION.md, 11-bo'lim](docs/INTEGRATION.md#11-kalitlar-api).

## Xato va crash hisobotlari

SDK foydalanuvchi duch kelgan xatolarni va SDK ichida boshlangan crash'larni
YT gateway'iga yuboradi. Bu doim yoqilgan, o'chirib bo'lmaydi.

- **Yuboriladi:** amal (kalit qo'shish, imzolash, QR skanerlash, kalitni
  o'chirish), xato kodi, foydalanuvchiga ko'rsatilgan xabar, kalit turi, SDK
  va iOS versiyasi, qurilma modeli, crash bo'lsa — uning stack'i.
- **Hech qachon yuborilmaydi:** ism, JSHSHIR/STIR, sertifikat seriya raqami,
  parol, PIN, QR kod, hujjat yoki uning hesh'i. Bunday qiymatlar telefondan
  chiqishdan oldin tozalanadi.

Crash keyingi ishga tushishda yuboriladi; ilovangizning o'z crash reporter'i
ham uni oladi. Faqat SDK kodida boshlangan crash yuboriladi, ilovaning boshqa
crash'lari emas.

Gateway imzolarni ilova va kalit turi (PFX fayl, QR kod, ID karta, USB token,
BAIK token) bo'yicha sanaydi. Nima imzolangani va kim imzolagani saqlanmaydi.

### App Store: App Privacy

App Store Connect → **App Privacy**'da **Crash Data** va **Other Diagnostic
Data**ni e'lon qiling: foydalanuvchiga bog'lanmagan (Not Linked to You),
kuzatish uchun ishlatilmaydi (Not Used for Tracking), maqsadi **App
Functionality**. SDK o'zining privacy manifest'i (`PrivacyInfo.xcprivacy`)
bilan keladi.

## SDK qanday ishlaydi?

1. **Ishga tushish** — SDK kriptografiyani tekshiradi (self-test) va YT gateway'ida sessiya ochadi: App Attest bilan, ilovada litsenziya bo'lsa — litsenziya bilan. Gateway ilovani yoki qurilmani rad etsa, bloklangan ekran chiqadi.
2. **Bosh sahifa** — asosiy kalit, IMZOLASH tugmasi, kalitlar ro'yxati.
3. **Kalit qo'shish** — bitta ro'yxatdan: PFX fayl, QR, ID karta (NFC), USB token, BAIK token.
4. **Imzo** — ilova bergan so'rov (`deepLink`) yoki IMZOLASH bosilib skanerlangan QR:
   - tasdiq ekrani: domen, hesh, kalit; imzo faqat shu ekrandagi IMZOLASH'dan keyin
   - parol yoki PIN (parol saqlangan bo'lsa, so'ralmaydi)
   - OzDST 1092 imzo + `pki.send_pkcs7` — E-IMZO'ga gateway orqali
   - «Imzolandi» → `onSignComplete`
5. **Xatolar** — ekran tepasidagi bannerda, oddiy jumla bilan. SDK matnlari o'zbek, rus va ingliz tilida; til SDK'ning o'z sozlamalarida tanlanadi, ilovangiz tili o'zgarmaydi.

## 2.2 dan o'tish

1. Ilovani `info@yt.uz` orqali ro'yxatdan o'tkazing: bundle ID, Team ID, `dev` va/yoki `prod`. Ro'yxatdan o'tmaguncha SDK bloklangan ekranni ko'rsatadi, shuning uchun buni sinovdan oldin qiling. Sinovni haqiqiy qurilmada o'tkazing.
2. Ilovada litsenziya bo'lsa: avval `info@yt.uz`'ga yozing, YT tasdiqlaguncha 2.2 da qoling.
3. `Info.plist`dagi `CFBundleURLTypes`dan `eimzo` sxemasini va `eimzo://` uchun `onOpenURL` ishlovchisini olib tashlang. Imzo so'rovini `EImzoSignLink.create(siteId:documentId:hash:)` bilan yasang.
4. `EImzoConfig(isTestMode:)` o'rniga `EImzoConfig(environment:)` yozing.
5. Sheet'ni `onSignComplete`da yoping: u «Ilovaga qaytish»dan (yoki taxminan 3 soniyadan) yoki «Tayyor»dan keyin keladi.
6. App Store Connect → App Privacy: Crash Data va Other Diagnostic Data.
7. SPM: `from: "2.4.1"`.

2.3 dan oldin qo'shilgan ID karta va USB token kalitlarida muddat noto'g'ri saqlangan va JSHSHIR yo'q. To'g'rilash uchun kalitni qayta qo'shish kerak.

## Foydalanish misoli

Repodagi `EimzoExample.xcodeproj` (kodi `EimzoExample/` da) — SwiftUI ilova. U SDK'ni SPM orqali shu repodan oladi (`from: "2.4.1"`). Ikkita tugma `EImzoView`ni ochadi: so'rovsiz va `EImzoSignLink.create` bilan yasalgan imzo so'rovi bilan. `eimzo` sxemasi va `onOpenURL` yo'q, SDK `sheet(item:)` bilan ochiladi, muhitni ekrandagi «Test muhiti (dev)» tanlaydi (sukut bo'yicha `.dev`).

Pastdagi ikkita tugma — Kalitlar API. «Kalitlar ro'yxati» `EImzoAPI.getKeys`ni chaqiradi, qaytgan JSON'ni ko'rsatadi va undagi kalitlardan birini tanlatadi. «Tanlangan kalit bilan imzolash» o'sha imzo so'rovini shu kalit bilan `EImzoAPI.sign` orqali, SDK'ning imzo oynasida imzolaydi va natija JSON'ini ko'rsatadi. Kalitlar API uchun YT ruxsati kerak (yuqoridagi «Kalitlar API»): ruxsat bo'lmasa natija `{"status":"error","code":"api_not_allowed",…}`. Ro'yxat bo'sh bo'lsa, kalitni avval `EImzoView`da qo'shing.

Ishga tushirish: `EimzoExample.xcodeproj`ni oching, Signing & Capabilities'da Team'ingizni tanlang va bundle ID'ni o'zingiznikiga almashtiring. Shu bundle ID va Team ID ro'yxatdan o'tgan bo'lishi kerak (yuqoridagi «Ro'yxatdan o'tish»), aks holda SDK bloklangan ekranni ko'rsatadi, Kalitlar API esa `blocked` qaytaradi. Ilovani haqiqiy iPhone'da sinang: iOS Simulator'da App Attest ishlamaydi, u yerda ham shunday bo'ladi.

## Documentation

- [INTEGRATION.md](docs/INTEGRATION.md) — to'liq integratsiya qo'llanma
- [MANUAL_INSTALLATION.md](docs/MANUAL_INSTALLATION.md) — SPM'siz Xcode'ga qo'lda qo'shish

## Versiya tarixi

[CHANGELOG.md](CHANGELOG.md)

## Litsenziya

Closed-source. Foydalanish uchun `info@yt.uz` orqali bog'laning.
