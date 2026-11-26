# Manual installation

SPM o'rniga `EimzoSDK.xcframework`'ni Xcode'ga to'g'ridan-to'g'ri qo'shish.

## 1. Yuklab olish

[GitHub Releases](https://github.com/peachdev-uz/eimzo-ios-sdk/releases) →
`2.8.0` release'dan `EimzoSDK.xcframework.zip` faylini yuklang.

Yoki Terminal'da:
```bash
curl -L -O https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.8.0/EimzoSDK.xcframework.zip
shasum -a 256 EimzoSDK.xcframework.zip
unzip EimzoSDK.xcframework.zip
```

`shasum` natijasi `2.8.0` tegidagi [`Package.swift`](../Package.swift)dagi
`checksum` qiymati bilan bir xil bo'lishi kerak.

## 2. Xcode'ga qo'shish

1. Xcode'da loyihangizni oching.
2. App target'ni tanlang.
3. **General** → **Frameworks, Libraries, and Embedded Content** ostiga
   `EimzoSDK.xcframework`'ni drag-and-drop qiling.
4. **Embed** ustunida **Embed & Sign**'ni tanlang.

## 3. Foydalanish

Endi qolgan qadamlar SPM holatidagi kabi: ilovani ro'yxatdan o'tkazing,
`Info.plist` kalitlarini qo'shing, `import EimzoSDK` qilib `EImzoView`ni
present qiling. [INTEGRATION.md](INTEGRATION.md) ga qarang.

## Yangilash

Yangi versiya chiqsa, eski `EimzoSDK.xcframework`'ni Xcode'dan o'chirib,
yangisini xuddi shunday qo'shing. Nima o'zgarganini avval
[CHANGELOG.md](../CHANGELOG.md)dan ko'ring.

### 2.7 va undan eski versiyadan o'tish

2.7 gacha SDK ikkita fayl edi: `EimzoSDK.xcframework` va
`Pfx2qr.xcframework`. 2.8.0 dan `Pfx2qr.xcframework` yo'q va kerak emas: PFX
kalit fayli endi `EimzoSDK`ning o'zida o'qiladi. Yangilashda
`Pfx2qr.xcframework`'ni loyihadan olib tashlang: **Frameworks, Libraries,
and Embedded Content** ro'yxatidan o'chiring va faylning o'zini ham
o'chiring. Kodda hech narsa o'zgarmaydi.
