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

Version rule: **Up to Next Major Version** dan **2.5.0**. Product:
`EimzoSDK`.

`Package.swift`da:

```swift
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "2.5.0")
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
.package(url: "https://github.com/peachdev-uz/eimzo-ios-sdk", from: "2.5.0")
```

`from: "2.5.0"` semantic versioning bo'yicha 2.5.0 va undan yangi 2.x
versiyalarni qabul qiladi, 3.0.0 ni olmaydi.

## 11. Kalitlar API

2.4.0 dan SDK'da `EImzoView`dan tashqari ikkita usul bor:

- `EImzoAPI.getKeys(config:)` — foydalanuvchi telefonda SDK'ga qo'shgan
  kalitlar ro'yxati;
- `EImzoAPI.sign(keyId:deepLink:config:)` — shu kalitlardan biri bilan imzo,
  SDK'ning o'z imzo oynasi orqali.

Ikkalasi `async`, JSON'ni `String` qilib qaytaradi — main actor'da, bir
marta. Usul nomlari, JSON shakli va xato kodlari Android SDK va Flutter
plaginida ham shunday.

### Ruxsat

Kalitlar API faqat YT ruxsat bergan integratorda ishlaydi. Ruxsatni
`info@yt.uz` orqali so'rang: u shartnoma tuzilgandan keyin beriladi va
integratorning barcha ilovalariga tegishli. Ilova avvalgidek ro'yxatdan
o'tgan bo'lishi kerak (1-bo'lim). Ruxsat bo'lmasa, ikkala usul
`api_not_allowed` xatosini qaytaradi; ruxsat o'chirilsa, ochiq `sign` ham shu
xato bilan tugaydi.

`EImzoView` avvalgidek ro'yxatdan o'tgan har bir integratorga ochiq.
Foydalanuvchi kalitlarini o'sha yerda qo'shadi (PFX fayl, QR, ID karta, USB
token, BAIK token): API kalit qo'shmaydi.

Tekshiruv uchun alohida init yo'q: har bir usul litsenziya va gateway
tekshiruvini kerak bo'lganda o'zi bajaradi. API bloklangan ekranni
ko'rsatmaydi — rad etish `blocked` xatosi bo'lib qaytadi. App Attest faqat
haqiqiy qurilmada ishlaydi, shuning uchun API'ni ham qurilmada sinang.

### Kalitlar ro'yxati

```swift
let json = await EImzoAPI.getKeys(config: EImzoConfig(environment: .prod))
```

```json
{"status":"ok","keys":[
  {"id":"7a3f…","pinfl":"31234567890123","name":"ALIYEV VALI ALIYEVICH",
   "type":"pfx","validFrom":"2025-03-01","validTo":"2027-03-01"}
]}
```

- `id` — sertifikat seriya raqami, SDK saqlaganidek. Uni o'zgartirmasdan
  `sign`ga bering.
- `pinfl` — JSHSHIR; sertifikatda bo'lmasa `null`.
- `name` — sertifikat egasining ismi.
- `type` (2.5 dan) — kalit turi: `pfx` (kalit fayli, fayldan yoki QR koddan
  qo'shilgan), `id_card` (ID karta) yoki `token` (USB yoki BAIK token).
  Boshqa qiymat kelsa (keyingi versiyalarda yangi tur qo'shilishi mumkin),
  uni oddiy kalit deb ko'rsating.
- `validFrom`, `validTo` — `yyyy-MM-dd` (soatsiz); SDK sanani o'qiy olmasa
  `null`.

Ro'yxatda tanlangan muhitda (`environment`, 6-bo'lim) ishlatsa bo'ladigan
barcha turdagi kalitlar bor. Muddati o'tganlari ham kiradi — ularni
`validTo` bo'yicha «muddati o'tgan» deb ko'rsating. Boshqa muhitda
qo'shilgan kalit kirmaydi. Tartib SDK'ning o'z ro'yxatidagidek: asosiy kalit
birinchi. Kalit bo'lmasa — `{"status":"ok","keys":[]}`.

Bitta odamning bir nechta kaliti bo'lsa (masalan, ID karta, token va kalit
fayli), har biri alohida yozuv: `id` lari har xil, `pinfl` va `name` bir xil,
`type` qaysi biri qaysi ekanini aytadi.

STIR, tashkilot, parol va kalitning o'zi qaytarilmaydi.

### Imzo

So'rov havolasi avvalgidek ilova ichida yasaladi (5-bo'lim):

```swift
let link = try EImzoSignLink.create(siteId: siteId, documentId: documentId, hash: hash)
let json = await EImzoAPI.sign(keyId: key.id, deepLink: link, config: config)
```

`sign` avval tekshiradi, shu tartibda, va birinchi o'tmagan tekshiruv
xatosini hech narsa ochmasdan qaytaradi: ruxsat, so'rov (`invalid_request`),
kalit shu telefonda va shu muhitda bormi (`key_not_found`), muddati
(`key_expired`), boshqa `sign` ochiq emasmi (`busy`).

Keyin SDK imzo oynasini ilovaning eng ustki ekrani ustida (key window'ning
eng ustki view controller'i, sheet) ochadi. Oynada sayt (domen), hesh va
siz tanlagan kalit; boshqa kalitga almashtirib bo'lmaydi. Foydalanuvchi
IMZOLASH'ni bosadi va faqat shu oynada parolni (PFX yoki QR kalit; saqlangan
parol avvalgidek ishlatiladi) yoki PIN'ni (ID karta — kartani tutadi; USB
yoki BAIK token — token ulangan bo'ladi) kiritadi. Imzodan keyin
«Imzolandi» ekrani 3 soniyadan keyin o'zi yopiladi, shundan keyin `sign`
qaytadi.

- `{"status":"signed"}` — E-IMZO imzoni qabul qildi.
- `{"status":"cancelled"}` — foydalanuvchi oynani imzolamasdan yopdi. Oyna
  ko'rsatgan, foydalanuvchi tuzatsa bo'ladigan xatodan keyin yopilsa ham
  shunday: noto'g'ri parol yoki PIN (urinish qolgan bo'lsa), karta yoki token
  yo'q yoki boshqasi, internet yo'q, javob kelmadi.
- `{"status":"error","code":"…","message":"…"}` — tekshiruv o'tmadi yoki
  oqim xato bilan tugadi:
  - oyna darhol, SDK xabarisiz yopiladi: gateway yoki litsenziya rad etdi
    (`blocked`), ruxsat o'chirildi (`api_not_allowed`), E-IMZO so'rovning
    saytini ro'yxatdan o'tmagan dedi (`invalid_request`);
  - SDK avval sababini oynada ko'rsatadi (`EImzoView`dagidek), foydalanuvchi
    uni yopgach (yoki oynani yopsa) xato qaytadi: kalit muddati tugagan
    (`key_expired`), E-IMZO imzoni rad etdi — hujjat muddati o'tgan yoki
    topilmadi, sertifikat rad etildi (`sign_failed`, E-IMZO'ning so'zlari
    `message`da), karta yoki token PIN'i bloklandi (`sign_failed`, `message`
    — `pin_blocked`).

Bir vaqtda bitta `sign` ochiq bo'ladi. Ilovangiz o'z oynasini yopayotgan
paytda chaqirsangiz, SDK u yopilishini bir necha soniya kutadi.

Imzolangan hujjat (PKCS#7) ilovaga qaytmaydi: uni E-IMZO avvalgidek sizning
backend'ingizga yuboradi. `signed`dan keyin hujjat holatini backend'dan
oling. Har bir imzo YT gateway orqali o'tadi va gateway'da Kalitlar API
imzosi sifatida sanaladi.

```swift
struct EImzoReply: Decodable {
    struct Key: Decodable {
        let id: String
        let pinfl: String?
        let name: String
        let type: String?     // 2.5 dan; eski SDK'da yo'q
        let validFrom: String?
        let validTo: String?
    }
    let status: String        // "ok", "signed", "cancelled", "error"
    let keys: [Key]?          // getKeys
    let code: String?         // xato bo'lsa
    let message: String?
}

func decode(_ json: String) throws -> EImzoReply {
    try JSONDecoder().decode(EImzoReply.self, from: Data(json.utf8))
}

let reply = try decode(await EImzoAPI.sign(keyId: key.id, deepLink: link, config: config))
switch reply.status {
case "signed":    break   // hujjat holatini backend'dan oling
case "cancelled": break   // foydalanuvchi imzolamadi
default:          print(reply.code ?? "", reply.message ?? "")
}
```

### Xato kodlari

| `code` | Qachon |
|---|---|
| `api_not_allowed` | integratorda «Kalitlar API» ruxsati yo'q yoki o'chirilgan |
| `blocked` | litsenziya tekshiruvi yoki gateway ilovani yoki qurilmani rad etdi; `message` gateway kodi bilan boshlanadi (masalan `app_blocked: …`), telefondagi litsenziya rad etilsa — `licence: …` |
| `network` | gateway'ga ulanib bo'lmadi yoki javob kelmadi |
| `invalid_request` | `deepLink` imzo so'rovi emas yoki E-IMZO uning saytini ro'yxatdan o'tmagan dedi |
| `key_not_found` | bu `id` bilan shu muhitda ishlatsa bo'ladigan kalit yo'q |
| `key_expired` | kalit sertifikati muddati tugagan (SDK yoki E-IMZO aytdi) |
| `busy` | boshqa `sign` hali ochiq |
| `sign_failed` | E-IMZO imzoni rad etdi (so'zlari `message`da), karta yoki token PIN'i bloklandi (`message`: `pin_blocked`) yoki oqim boshqa xato bilan tugadi |

`message` — ishlab chiquvchi uchun inglizcha matn, foydalanuvchiga
ko'rsatish uchun emas; unda kalit, parol yoki hesh bo'lmaydi. Android'dagi
`not_initialized` iOS'da qaytmaydi: iOS'da init qadami yo'q.

## 12. Dizayn (2.5.0 dan)

SDK ekranlari ilovangiz ranglari, shrifti va burchaklarida chiqishi mumkin.
Hammasi `EImzoConfig`da beriladi; `appearance` yo'q bo'lsa SDK o'z dizaynida.

```swift
let config = EImzoConfig(
    environment: .prod,
    appearance: EImzoAppearance(
        light: EImzoPalette(primary: Color("Brand"), background: .white,
                            surface: Color("Card"), text: Color("Text"),
                            textSecondary: Color("TextSecondary"), divider: Color("Divider")),
        dark: EImzoPalette(primary: Color("Brand"), background: Color("BackgroundDark"),
                           surface: Color("CardDark"), text: .white),
        themeMode: .system,
        fontFamily: "Inter",
        cornerRadius: 12
    ),
    language: .ru,
    showsLanguagePicker: false,
    hashDisplay: .hidden
)
```

- **Ranglar.** Har rejim uchun 6 ta: `primary`, `background`, `surface`,
  `text`, `textSecondary`, `divider`. Berilmagan rang SDK'niki. `dark`
  berilmasa tungi rejimda SDK'ning tungi ranglari, lekin `primary` sizniki
  (tungi fonda o'qiladigan qilib moslanadi). Asset katalogidagi light/dark
  rang har rejimda o'z variantida o'qiladi. Shaffoflik hisobga olinmaydi.
- **Kontrast.** `text` `background` yoki `surface`da 4.5:1 dan past o'qilsa,
  o'sha rejimning ranglari olinmaydi va konsolga sababi yoziladi. Havola rangi,
  ikkinchi darajali matn va tugma ustidagi matn kontrastga o'zi moslanadi.
- **Shrift.** `fontFamily` — ilova `UIAppFonts` orqali ro'yxatdan o'tkazgan
  oila (yoki uning bitta yuzining nomi). SDK regular, medium va semibold
  yuzlarini oladi va Dynamic Type bilan kattalashtiradi.
- **Rejim.** `themeMode: .light`/`.dark` faqat SDK ekranlariga ta'sir qiladi;
  `EImzoView`ni sheet yoki fullScreenCover ichida ko'rsating.
- **Til.** `language` + `showsLanguagePicker: false` — ilovaning o'z til
  tanlovi bo'lsa, joriy tilini har safar shu yerda bering.
- **Hash.** `hashDisplay: .hidden` faqat ilova bergan so'rovga tegishli;
  SDK skaneri o'qigan QR'da hash doim ko'rinadi.
- **O'zgarmaydi:** sayt nomi, kalit egasi, «Imzolash» (rangi `primary`dan),
  PIN/parol oynasi, xato va ogohlantirish ranglari, yashil «Imzolandi»
  belgisi, kalit kartasi, QR skaner.
- `appearance` va til sozlamalari litsenziya tekshiruviga ta'sir qilmaydi:
  ko'rinishni o'zgartirish qayta tekshiruv talab qilmaydi.
