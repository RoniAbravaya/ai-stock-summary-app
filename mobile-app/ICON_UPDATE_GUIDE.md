# App Icon Update Guide for MarketMind AI

## Quick Update Using Flutter Package

### 1. Place Your Icon
Put your app icon (1024x1024px PNG) at:
```
mobile-app/assets/icons/app_icon.png
```

### 2. Run Icon Generator
```bash
cd mobile-app
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required sizes for both Android and iOS.

## Manual Update (If Needed)

### Android Icon Sizes Required
Place icons in `android/app/src/main/res/`:

- `mipmap-mdpi/ic_launcher.png` - 48x48px
- `mipmap-hdpi/ic_launcher.png` - 72x72px
- `mipmap-xhdpi/ic_launcher.png` - 96x96px
- `mipmap-xxhdpi/ic_launcher.png` - 144x144px
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192px

### iOS Icon Sizes Required
Place icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:

- Icon-App-20x20@1x.png - 20x20px
- Icon-App-20x20@2x.png - 40x40px
- Icon-App-20x20@3x.png - 60x60px
- Icon-App-29x29@1x.png - 29x29px
- Icon-App-29x29@2x.png - 58x58px
- Icon-App-29x29@3x.png - 87x87px
- Icon-App-40x40@1x.png - 40x40px
- Icon-App-40x40@2x.png - 80x80px
- Icon-App-40x40@3x.png - 120x120px
- Icon-App-60x60@2x.png - 120x120px
- Icon-App-60x60@3x.png - 180x180px
- Icon-App-76x76@1x.png - 76x76px
- Icon-App-76x76@2x.png - 152x152px
- Icon-App-83.5x83.5@2x.png - 167x167px
- Icon-App-1024x1024@1x.png - 1024x1024px

## Icon Design Recommendations

### Best Practices
- **Size**: 1024x1024px original
- **Format**: PNG with transparency
- **Style**: Simple, recognizable at small sizes
- **Colors**: Match your brand
- **Safe Area**: Keep important elements in the center 80%

### Avoid
- Text that's too small to read
- Too much detail
- Photos (use simplified graphics)
- Gradients that don't scale well

## Testing
After updating icons:
1. Clean build folders
2. Rebuild the app
3. Test on actual devices (not just simulator)

```bash
# Clean
flutter clean
cd android && ./gradlew clean && cd ..

# Rebuild
flutter build appbundle  # For Android
flutter build ios        # For iOS
```

## Current Display Name
? **MarketMind AI** - Updated on both platforms

## Package Identifiers (UNCHANGED)
- Package name: `ai_stock_summary` (unchanged - used for Play Store)
- Bundle ID: Check `android/app/build.gradle` and `ios/Runner.xcodeproj`

These identifiers remain the same to maintain your Play Store registration.
