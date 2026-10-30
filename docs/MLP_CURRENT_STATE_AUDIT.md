# MYLife Plan - Current State Audit

## 1. Overview
The current application is a well-structured, highly animated Habit Tracker with gamification (XP, Badges, Streaks, Focus Sessions, 30-day Journey). It uses `provider` (with a massive `AppState` god-object) and Firebase (Auth, Firestore) for data sync. 
It does **not** yet contain the core learning, diagnostic, and AI roadmap features required for the MLP 2.0 Universal Self-Learning Platform.

## 2. Architecture & State Management
- **State Object:** `lib/providers/app_state.dart` is ~1500 lines long. It handles everything: local storage serialization, cloud dual-writing, business logic for XP/leveling, badge unlocks, and habit tracking.
- **Data Flow:** Uses a robust `_toAppData()` JSON serialization strategy. It correctly handles Guest Mode vs Cloud Sync and offers a merge strategy (`GuestDataChoice`).
- **Dependencies:** Both `provider` and `flutter_riverpod` are in `pubspec.yaml`, though the app currently relies entirely on `ChangeNotifierProvider` (`AppState`). The Riverpod addition seems incomplete/transitional.

## 3. Key Issues Identified
1. **Compilation Blocker (Fixed):** `CoinTransaction` imported `equatable`, but the package was missing from `pubspec.yaml`. (Resolved by adding `equatable`).
2. **Logic Bug in Habit Recovery:** `habit.needsRecoveryOn()` fails on the first day of creation because it checks the prior day.
3. **UI State Loss:** `DashboardShell` rebuilds tabs from scratch using an array of widgets `pages[index]`. Scroll positions and active states are destroyed on tab switch.
4. **Localization Mix:** The app mixes English UI ("Today's Habits", "Smart Coach") with hardcoded Uzbek content (`GrowthFocus` starter habits, dialog strings).
5. **Deprecated UI Code:** Heavy use of `withOpacity` instead of modern `withValues(alpha: ...)`.
6. **No AI Infrastructure:** No existing models for Goals, Roadmaps, or AI conversations.

## 4. Strengths to Preserve
- **Authentication:** The Google Sign-In and local Guest Mode flows are solid and should be kept.
- **Persistence:** Local/Cloud dual-write logic is robust.
- **Premium UI:** Glassmorphism (`GlassCard`), progress rings, and custom ambient animations (`_AnimatedBackground`) give it a premium feel. These aesthetic choices align with the requested design system and should be adapted, not deleted.
- **Local Notifications:** The `NotificationService` handles timezone-aware local scheduling well.
