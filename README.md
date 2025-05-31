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