# Manual installation

SPM o'rniga `.xcframework`'ni Xcode'ga to'g'ridan-to'g'ri qo'shish.

## 1. Yuklab olish

[GitHub Releases](https://github.com/peachdev-uz/eimzo-ios-sdk/releases) →
oxirgi versiyadan `EimzoSDK.xcframework.zip`'ni yuklang.

Yoki Terminal'da:
```bash
curl -L -o EimzoSDK.xcframework.zip \
  https://github.com/peachdev-uz/eimzo-ios-sdk/releases/download/1.0.0/EimzoSDK.xcframework.zip
unzip EimzoSDK.xcframework.zip
```

## 2. Xcode'ga qo'shish

1. Xcode'da loyihangizni oching.
2. App target'ni tanlang.
3. **General** → **Frameworks, Libraries, and Embedded Content** ostiga
   `EimzoSDK.xcframework`'ni drag-and-drop qiling.
4. **Embed** ustunini **Embed & Sign** ga o'rnating.

## 3. Foydalanish

Endi qolgan qadamlar SPM holatidagi kabi — `import EimzoSDK` qilib
`EImzoView` ni present qiling. [INTEGRATION.md](INTEGRATION.md) ga qarang.

## Yangilash

Yangi versiya chiqsa, eski `EimzoSDK.xcframework`'ni Xcode'dan o'chirib,
yangisini drag-and-drop qiling. Yoki Terminal'da o'zgartirib qoldiring.
