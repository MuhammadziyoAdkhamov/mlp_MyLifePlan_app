# MYLife Plan - Implementation Plan

## Phase 1: Audit and Foundation (Completed)
- [x] Inspect existing codebase.
- [x] Fix baseline errors (`equatable` dependency added).
- [x] Define migration and feature roadmap.

## Phase 2: Design System & Navigation Resilience
- **Refactor `DashboardShell`**: Replace naive array indexing with `StatefulShellRoute` (GoRouter) or `IndexedStack` to preserve tab state and scroll positions.
- **Theme Standardization**: Clean up deprecated `withOpacity` calls. Ensure colors align with the `AppColors` token system.

## Phase 3: Goals and Diagnostics Models
- **Domain Models**: Create `LearningGoal`, `DiagnosticResult`, and `LearningRoadmap` models.
- **Goal Creation UI**: Build the free-form text input screen for users to define "I want to learn Flutter" or "I want to speak B1 English".
- **Diagnostic Flow UI**: Build the dynamic Q&A interface for the AI to ask clarifying questions about the user's level and available time.

## Phase 4: Roadmap Generation & Home Screen Revamp
- **Roadmap Screen**: A UI to display, edit, and approve the generated step-by-step learning stages.
- **Home Screen Refactor**: Convert `HomeScreen` from merely showing "Today's Habits" to showing the **Next Learning Action** (e.g., "Start Lesson 2", "Review Algebra"). Existing habit lists will be moved to a secondary section or integrated as daily tasks.

## Phase 5: Learning, Practice, and Assessment
- **Lesson Screen**: UI to read/consume content.
- **Practice UI**: Support multiple choice, text input, and step-by-step problem-solving.
- **Assessment Logic**: Evaluate answers, store `MasteryRecords`, and determine the adaptive next step (Advance vs. Review).

## Phase 6: AI Ustoz Integration
- **Backend Boundary**: Create an `AITutorService` that abstracts the prompt/LLM calls. Initially implement this with a mock/stub that returns structured JSON to prove the UI works without live API keys, as requested by the prompt ("build the integration boundary... honest development fallback").
- **Explainer & Coach UI**: The conversational interface that ties into the current `LearningGoal`.

## Phase 7: Progress & Review
- **Mastery Dashboard**: Track progress not by "time spent" but by actual demonstrated knowledge.
- **Review Queue**: Implement spaced repetition logic based on assessment failures.

## Phase 8: Final Polish
- Ensure Firebase security rules are considered (document them).
- Run `flutter analyze` and widget tests.
