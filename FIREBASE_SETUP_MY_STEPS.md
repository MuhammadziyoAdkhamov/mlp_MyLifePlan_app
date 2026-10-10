# MYLife Plan Firebase setup

Package name: `uz.mylife.plan`

1. Firebase Console -> Create project.
2. Project Settings -> Add app -> Android.
3. Android package name: `uz.mylife.plan`.
4. Authentication -> Sign-in method -> Google -> Enable.
5. Firestore Database -> Create database.
6. Firestore Rules -> paste `firestore.rules` content and Publish.
7. Terminal in project root:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

8. Get SHA-1:

```bash
cd android
.\gradlew signingReport
```

9. Add SHA-1 in Firebase Project Settings -> Android app -> SHA certificate fingerprints.
10. Download fresh `google-services.json` and put it here:

```text
android/app/google-services.json
```

11. Run:

```bash
flutter clean
flutter pub get
flutter run
```
