# AI Stock Summary App - Full Technical Specification & Deployment Guide

## Overview

This document defines the complete specification and step-by-step instructions to build, configure, and deploy the AI-powered Stock Summary mobile application using **Flutter** for the frontend and **Node.js with Firebase** for the backend services.

---

## Stack Summary

* **Frontend**: Flutter (cross-platform for iOS & Android)
* **Backend**: Node.js + Express
* **Database**: Firebase Firestore (NoSQL)
* **Authentication**: Firebase Auth (Google, Facebook, Email/Password)
* **Storage**: Firebase Storage
* **AI Service**: OpenAI GPT-3.5 API
* **Push Notifications**: Firebase Cloud Messaging (FCM)
* **Ads & Subscriptions**: Google AdMob + Google Play Billing
* **Analytics**: Firebase Analytics

---

## 1. Features Summary

### Users

* Register/Login (Google, Facebook, Email)
* Dashboard (trending stocks)
* Favorites tab (AI summary and Generate button)
* News tab (latest financial news)
* Profile tab (usage stats, subscription status, settings)
* View AI summaries
* Watch rewarded ads to gain extra summaries
* Upgrade to premium for 100 summaries/month

### Admin

* Access secure admin tab in app
* Send push notifications to users
* Manage user roles (grant/revoke admin rights)

---

## 2. Project Structure

```
project-root/
├── backend/                # Node.js + Firebase Functions
│   ├── api/                # Express API endpoints
│   ├── services/           # AI logic, data handlers
│   ├── utils/              # Helper methods
│   └── index.js            # Entry point
├── mobile-app/            # Flutter project
│   ├── lib/
│   │   ├── screens/        # Login, Home, Favorites, etc.
│   │   ├── widgets/
│   │   ├── services/       # API, Auth, etc.
│   │   ├── models/
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

---

## 3. Execution Process (Step-by-Step)

### Step 1: Set Up Firebase

* Create a Firebase project
* Enable Firestore, Firebase Auth, Firebase Storage
* Set up Google, Facebook, and Email sign-in
* Create Cloud Messaging credentials for push notifications
* Enable AdMob and in-app purchases in Google Play Console

### Step 2: Flutter Project Setup

```bash
flutter create mobile-app
cd mobile-app
flutter pub add firebase_core firebase_auth cloud_firestore firebase_messaging google_sign_in flutter_facebook_auth google_fonts http shared_preferences
flutter pub add firebase_analytics
flutter pub add google_mobile_ads in_app_purchase
```

### Step 3: Backend Setup

```bash
mkdir backend && cd backend
npm init -y
npm install express firebase-admin axios cors openai
```

* Setup Express server
* Configure Firebase Admin SDK
* Implement AI summary endpoint using OpenAI
* Create Firestore triggers and business logic

### Step 4: Generate API Endpoints

* `/summary/generate`: Generate AI summary
* `/summary/get`: Fetch summary
* `/summary/translate`: Translate summary
* `/auth/grant-admin`: Promote user to admin
* `/push/send`: Send push notifications

### Step 5: Flutter App Integration

* Configure Firebase using `google-services.json`
* Create login screens
* Implement tabs: Dashboard, Favorites, News, Profile
* Integrate API endpoints
* Add logic to handle summary generation and reward ads

### Step 6: Ads and Subscriptions

* Setup rewarded video ads (Google AdMob)
* Setup Google Play Billing for 100 summaries/month plan
* Track summary usage, reset monthly
* Limit one ad view at a time

### Step 7: Analytics and Crashlytics

* Use Firebase Analytics to track:

  * Summary generations
  * Reward ad views
  * Sign-in method
  * Button taps and navigation

### Step 8: Admin Dashboard (In-App)

* Tab visible only to admin users
* Role-based access control via Firestore
* Admin can:

  * Grant/remove admin
  * Send custom push notification

---

## 4. Backend Summary Logic

### AI Summary

* Triggered only for favorite stocks
* Uses latest price history + news (RapidAPI)
* Saved in DB with language variants
* Cached per language

### Monthly Limits

* Free: 10 summaries/month
* Premium: 100 summaries/month
* Reward ad = +1 summary
* Expiration resets monthly (auto)

---

## 5. Multilingual Support

* App supports multiple languages
* Summaries translated automatically using AI
* Displayed based on selected app language
* Translation stored per language in DB

---

## 6. Deployment

### Firebase

```bash
firebase init functions
firebase deploy --only functions
```

### Flutter

```bash
flutter build appbundle
```

### Play Store

* Upload `.aab` to Google Play
* Setup in-app purchases
* Upload keystore for signing

---

## Notes

* App requires internet access
* All features are hardcoded, no feature flags
* No manual summary input by users
* Summaries tied to stock IDs, latest only

---

## Next Step

See `Firebase-Google-Setup.md` for Firebase & Google Console configuration instructions.
