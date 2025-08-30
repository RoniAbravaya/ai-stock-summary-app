# AI Stock Summary App

A comprehensive Flutter + Node.js + Firebase application for AI-powered stock summaries with authentication, ads, and subscription features.

## Project Structure

```
project-root/
├── backend/                # Node.js + Express API
│   ├── api/                # Express API endpoints
│   ├── services/           # AI logic, data handlers
│   ├── utils/              # Helper methods
│   └── package.json        # Backend dependencies
├── mobile-app/            # Flutter cross-platform app
│   ├── lib/
│   │   ├── screens/        # UI screens (Login, Home, Favorites, etc.)
│   │   ├── widgets/        # Reusable UI components
│   │   ├── services/       # API, Auth, etc.
│   │   ├── models/         # Data models
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml        # Flutter dependencies
├── .env                    # Root environment variables
└── README.md               # This file
```

## Tech Stack

- **Frontend**: Flutter (iOS & Android)
- **Backend**: Node.js + Express
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth (Google, Facebook, Email)
- **Storage**: Firebase Storage
- **AI Service**: OpenAI GPT-3.5 API
- **Push Notifications**: Firebase Cloud Messaging
- **Ads & Subscriptions**: Google AdMob + Google Play Billing
- **Analytics**: Firebase Analytics

## Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Node.js (v18+)
- Firebase CLI
- Android Studio / Xcode for mobile development

### Environment Setup
1. Copy `.env.example` to `.env` and fill in your credentials
2. Configure Firebase project and download config files
3. Set up OpenAI API key
4. Configure Google AdMob and Play Console

### Backend Setup
```bash
cd backend
npm install
npm run dev
```

### Mobile App Setup
```bash
cd mobile-app
flutter pub get
flutter run
```

## Features

### User Features
- Multi-platform authentication (Google, Facebook, Email)
- Dashboard with trending stocks
- Favorites management with AI summaries
- Latest financial news feed
- User profile with usage statistics
- Rewarded ads for extra summaries
- Premium subscription (100 summaries/month)

### Admin Features
- In-app admin panel
- Push notification management
- User role management

## Development Status

🚧 **Project is in initial setup phase**
- [x] Monorepo structure created
- [x] Flutter app initialized
- [x] Backend structure created
- [ ] Environment configuration
- [ ] Firebase setup
- [ ] Mock data implementation
- [ ] API endpoints
- [ ] UI implementation
- [ ] Testing setup

## License

[Add your license here] 

## Redesign (feature-flag)

The app includes a gated redesign that can be turned on per-device without affecting existing functionality.

- **Enable in app**: Open the Settings/Profile screen and toggle "Use new design". The choice is saved locally and persists across restarts.
- **What changes when enabled**:
  - Global theme using Inter typography, updated colors and shapes
  - Pill-shaped BottomNavigationBar with SafeArea padding and subtle blur (BackdropFilter) on scroll
  - Redesigned screens: News list, Stocks list, Stock Details (header + actions), Notification Settings, Notification History, Language Settings
  - Legacy UI is preserved when the toggle is OFF
- **Under the hood**:
  - Managed by `FeatureFlagService` with SharedPreferences key `feature_redesign_enabled`
  - Reactive switching via a stream surrounding `MaterialApp`
- **Programmatic toggle (for developers)**:
  - Set at runtime: `await FeatureFlagService().setRedesignEnabled(true);`
  - Or set the SharedPreferences key `feature_redesign_enabled = true`
- **Rollback**:
  - The redesign is fully gated by the toggle; disabling it restores legacy UI.
  - All changes are on branch `feature/redesign-flag-toggle` to allow safe rollback via Git if needed.