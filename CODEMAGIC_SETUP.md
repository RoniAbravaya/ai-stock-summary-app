# Codemagic Setup Guide for AI Stock Summary (MarketMind AI)

This guide walks you through setting up Codemagic to deploy your Flutter app to the Apple App Store.

## Prerequisites

Before starting, ensure you have:
- An Apple Developer account ($99/year)
- App Store Connect access
- Your app registered in App Store Connect
- A Codemagic account (free tier available)

## Step 1: Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Users and Access** → **Integrations** → **App Store Connect API**
3. Click **Generate API Key** (or use existing)
4. Select **Admin** or **App Manager** role
5. Download the `.p8` file and note:
   - **Issuer ID** (shown at top of page)
   - **Key ID** (shown next to key name)

> ⚠️ **Important**: The `.p8` file can only be downloaded once!

## Step 2: Register Your App in App Store Connect

1. Go to **Apps** in App Store Connect
2. Click **+** → **New App**
3. Fill in the details:
   - **Platform**: iOS
   - **Name**: MarketMind AI
   - **Primary Language**: English (or your preference)
   - **Bundle ID**: `com.marketmindai`
   - **SKU**: A unique identifier (e.g., `marketmind-ai-001`)
4. Note the **Apple ID** (numeric ID shown in app details) - you'll need this

## Step 3: Configure Codemagic

### 3.1 Add Your Repository

1. Log in to [Codemagic](https://codemagic.io/)
2. Click **Add application**
3. Connect your GitHub/GitLab/Bitbucket repository
4. Select **Flutter App** as the project type
5. Choose **codemagic.yaml** as your configuration

### 3.2 Set Up Code Signing Integration

1. Go to your app settings in Codemagic
2. Navigate to **Integrations** → **Developer Portal** 
3. Click **Connect** for App Store Connect
4. Enter:
   - **Issuer ID**: From Step 1
   - **Key ID**: From Step 1
   - **API Key**: Paste contents of `.p8` file
5. Name the integration: `Codemagic` (must match `codemagic.yaml`)

### 3.3 Configure Environment Variables

Go to **Environment variables** in your app settings and add:

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_STORE_APP_ID` | Numeric App ID from App Store Connect | `1234567890` |
| `BUNDLE_ID` | Your app's bundle identifier | `com.ai_stock_summary` |

### 3.4 (Optional) Firebase Configuration

If your `GoogleService-Info.plist` is not in the repository:

1. Base64 encode your plist:
   ```bash
   base64 -i GoogleService-Info.plist | pbcopy
   ```
2. Add as environment variable `GOOGLE_SERVICE_INFO_PLIST` (mark as Secure)
3. Uncomment the decode line in `codemagic.yaml`

## Step 4: Update codemagic.yaml

Update these values in `codemagic.yaml`:

```yaml
# In the ios-release workflow:
environment:
  vars:
    BUNDLE_ID: com.yourcompany.marketmindai  # Your actual bundle ID
    APP_STORE_APP_ID: "1234567890"           # Your actual App Store ID

# Update email recipients:
publishing:
  email:
    recipients:
      - your-actual-email@example.com
```

## Step 5: Prepare Your iOS Project

### 5.1 Check Bundle Identifier

Ensure your bundle ID matches across:
- `mobile-app/ios/Runner.xcodeproj/project.pbxproj`
- App Store Connect
- `codemagic.yaml`

Current bundle IDs:
- **iOS**: `com.marketmindai`
- **Android**: `com.ai_stock_summary`

> 💡 **Tip**: If you need to change the bundle ID, update it in Xcode project settings and `codemagic.yaml`.

### 5.2 Ensure GoogleService-Info.plist Exists

For Firebase to work, add `GoogleService-Info.plist` to your iOS project:
- Path: `mobile-app/ios/Runner/GoogleService-Info.plist`
- Download from Firebase Console → Project Settings → iOS app

### 5.3 Check Version Number

Your current version in `pubspec.yaml`:
```yaml
version: 1.0.1+32
```

Codemagic will auto-increment the build number for each build.

## Step 6: Trigger Your First Build

### Option A: Push to Main Branch
```bash
git add codemagic.yaml CODEMAGIC_SETUP.md
git commit -m "feat: add Codemagic CI/CD for iOS App Store deployment"
git push origin main
```

### Option B: Create a Version Tag
```bash
git tag v1.0.1
git push origin v1.0.1
```

### Option C: Manual Build
1. Go to your app in Codemagic dashboard
2. Click **Start new build**
3. Select **ios-release** workflow
4. Click **Start new build**

## Workflow Summary

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ios-release` | Push to `main`, tags starting with `v` | Build and deploy to TestFlight/App Store |
| `ios-development` | Pull requests | Build and test (no deployment) |
| `android-release` | Push to `main`, tags starting with `v` | Build and deploy to Play Store |

## Troubleshooting

### Build Fails at Code Signing

1. Verify App Store Connect integration is properly configured
2. Check bundle ID matches exactly
3. Ensure automatic code signing is set up in Codemagic

### CocoaPods Issues

If pods fail to install:
```bash
cd mobile-app/ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Flutter Version Issues

Update `codemagic.yaml` if you need a specific Flutter version:
```yaml
env_versions: &env_versions
  flutter: 3.24.0  # Specific version
  xcode: 15.0
```

### Build Number Conflicts

If you get "build already exists" error:
- Codemagic auto-increments, but check App Store Connect for the latest build number
- You can set `PROJECT_BUILD_NUMBER` in Codemagic to a higher value

## Useful Links

- [Codemagic Documentation](https://docs.codemagic.io/)
- [Flutter iOS Deployment](https://docs.codemagic.io/flutter-publishing/publishing-to-app-store/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Code Signing Guide](https://docs.codemagic.io/flutter-code-signing/ios-code-signing/)

## Next Steps

1. ✅ Complete App Store Connect app listing (screenshots, descriptions)
2. ✅ Set up TestFlight beta testers
3. ✅ Configure app privacy details in App Store Connect
4. ✅ Submit for App Store Review when ready (set `submit_to_app_store: true`)

---

*Last updated: December 2024*
