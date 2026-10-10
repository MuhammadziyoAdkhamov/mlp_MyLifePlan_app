# MYLife Plan — Habit Tracker & Self-Growth App

MYLife Plan is a Flutter-based habit tracking and personal growth mobile app.
The app helps users build daily discipline through habits, XP, streaks, badges, progress statistics, and cloud synchronization.

## Features

* Google Sign-In authentication
* Firebase Authentication integration
* Cloud Firestore user data synchronization
* Personal habit tracking
* Daily habit completion system
* XP and level progress
* Streak tracking
* Badge system
* Personal journey tasks
* Statistics and progress overview
* Premium dark UI design
* Local storage support
* Android real-device testing

## Tech Stack

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Google Sign-In
* Provider / App State Management
* Shared Preferences
* Custom UI Components

## Project Structure

```text
lib/
├── core/              # Theme, colors, spacing, helpers
├── models/            # App data models
├── providers/         # App state management
├── routes/            # App navigation
├── screens/           # Main app screens
├── services/          # Auth, cloud sync, local storage
└── widgets/           # Reusable UI components
```

## Firebase Setup

This repository does not include Firebase private configuration files.

To run the project locally, create a Firebase project and add your own Android configuration file:

```text
android/app/google-services.json
```

Required Firebase services:

* Firebase Authentication
* Google Sign-In provider
* Cloud Firestore

Firestore rules example:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
  }
}
```

## Running the App

Install dependencies:

```bash
flutter pub get
```

Run on a connected Android device:

```bash
flutter run
```

Build debug APK:

```bash
flutter build apk --debug
```

## Current Status

The app currently supports:

* Android build
* Google Authentication
* Firestore sync
* Habit data persistence
* Real-device testing

## Roadmap

* Improve UI polish and animations
* Add local notifications for habit reminders
* Add advanced statistics
* Improve Firestore data structure
* Add release build configuration
* Prepare Play Store-ready version

## Author

Developed by Muhammadziyo Adkhamov.
