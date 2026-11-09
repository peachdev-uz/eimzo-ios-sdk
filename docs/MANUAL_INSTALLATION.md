# Manual installation

SPM o'rniga `.xcframework`'larni Xcode'ga to'g'ridan-to'g'ri qo'shish.

## 1. Yuklab olish

[GitHub Releases](https://github.com/peachdev-uz/eimzo-ios-sdk/releases) →
`2.4.1` release'dan ikkala faylni yuklang: `EimzoSDK.xcframework.zip` va
`Pfx2qr.xcframework.zip`.

Yoki Terminal'da:
```bash
curl -L -O https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.4.1/EimzoSDK.xcframework.zip
curl -L -O https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/2.4.1/Pfx2qr.xcframework.zip
shasum -a 256 EimzoSDK.xcframework.zip Pfx2qr.xcframework.zip
unzip EimzoSDK.xcframework.zip
unzip Pfx2qr.xcframework.zip
```

`shasum` natijasi `2.4.1` tegidagi [`Package.swift`](../Package.swift)dagi
`checksum` qiymatlari bilan bir xil bo'lishi kerak.

## 2. Xcode'ga qo'shish

1. Xcode'da loyihangizni oching.
2. App target'ni tanlang.
3. **General** → **Frameworks, Libraries, and Embedded Content** ostiga
   `EimzoSDK.xcframework` va `Pfx2qr.xcframework`'ni drag-and-drop qiling.
4. **Embed** ustunida: `EimzoSDK.xcframework` — **Embed & Sign**,
   `Pfx2qr.xcframework` — **Do Not Embed** (u statik kutubxona).

## 3. Foydalanish

Endi qolgan qadamlar SPM holatidagi kabi: ilovani ro'yxatdan o'tkazing,
`Info.plist` kalitlarini qo'shing, `import EimzoSDK` qilib `EImzoView`ni
present qiling. [INTEGRATION.md](INTEGRATION.md) ga qarang.

## Yangilash

Yangi versiya chiqsa, eski ikkala `.xcframework`'ni Xcode'dan o'chirib,
yangilarini xuddi shunday qo'shing. Nima o'zgarganini avval
[CHANGELOG.md](../CHANGELOG.md)dan ko'ring.
