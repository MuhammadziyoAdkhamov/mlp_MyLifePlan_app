# MYLife Plan — Phase 1 Audit & Execution Notes

## Current quality estimate
Current state: ~68/100. The app has a strong habit-coach concept, Firebase-ready architecture, premium UI, smart habit fields, XP, badges, mood/energy, minimal version, skip reasons, and recovery foundations.

## Completed in this pass
- Added an explicit Guest Mode session API in `AppState`.
- Added `isGuestUser` and a clearer `syncStatusLabel` for guest/local/cloud states.
- Added a polished `Continue as Guest` action to the login screen.
- Added a profile backup prompt for guest users to sign in with Google and enable cloud sync.

## Critical issues still open
1. Real local notifications are missing.
2. Reminder strings are not scheduled/cancelled/rescheduled.
3. Frequency-aware streak logic is incomplete.
4. Recovery Mode is not backed by an exact 48-hour timestamp.
5. AppState remains too large and should be split after feature stabilization.
6. Firestore still stores most data in a large single document.
7. Release signing, Crashlytics, Analytics, privacy policy, and terms are incomplete.
8. The repository/export must exclude `.dart_tool`, `build`, `.gradle`, IDE folders, Firebase config, and signing files.

## Recommended next implementation phase
Phase 2 should implement `NotificationService` with:
- local notification permissions,
- daily scheduling based on habit reminder time,
- cancellation on habit delete/archive,
- rescheduling when reminders change,
- a Home Smart Reminder card.

After notifications, implement `StreakCalculator` for everyday/weekdays/weekends/custom frequencies.
