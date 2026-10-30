# MLP UI audit — 2026-10-28

Scope: existing active Flutter UI; no rewrite. Branch `feat/mlp-beta-sprint01`;
baseline HEAD `4a15b9e`, working tree contains prior uncommitted changes, including
a staged deletion of `lib/firebase_options.dart` that this audit preserves.
This report supersedes earlier unqualified “100%” demo claims. Code inspection,
widget rendering, device testing and production integrations are separate evidence.

## Inventory inspected

30 route declarations in `lib/app/router/mlp_routes.dart`, plus the background
settings page: **31 primary screen states**. Statistics and Progress share a page;
Project Details is a sheet, not an additional route. Nested task/habit/goal forms,
project/reward details, confirmations, time/date selection and the legacy workspace
remain in scope. Dormant alternate feature trees are not the active application.

| Screens | Actual source under repository root | Evidence / limits |
|---|---|---|
| Splash, Welcome, Registration, Login, Preferences | `lib/features/onboarding/mlp_account_flow.dart` | Entry gate and validation tests; login explicitly demo |
| Goal discovery, clarification, diagnosis, roadmap | `lib/features/goals/mlp_goal_flow.dart` | Free text goal, draft navigation, atomic roadmap tests |
| Goal details | `lib/features/goals/mlp_goal_detail.dart` | Edit/archive/delete and missing-ID states |
| Today, Projects, Tasks, project detail sheet | `lib/features/workspace/mlp_workspace_pages.dart` | Store-derived counts, filters, CRUD; new habit controls audited below |
| Calendar, schedule editor | `lib/features/planner/mlp_calendar.dart`, `lib/features/planner/mlp_schedule_editor.dart` | Recurrence/conflict/keyboard tests; reminders currently intent only |
| Focus hub, active focus, summary | `lib/features/focus/mlp_focus_pages.dart`, `lib/features/focus/mlp_focus_controller.dart` | Timestamp elapsed, 25/5/50/custom, pause/resume/save, break exclusion, idempotency |
| Chat, voice preview, AI preferences | `lib/features/ai_companion/mlp_companion_pages.dart`, `mlp_ai_orb.dart` in same directory | Local deterministic answers; voice states explicitly preview |
| Verification, passport, statistics/progress | `lib/features/progress/mlp_progress_pages.dart` | Self-report separate from sample quiz; no skill inference from focus time |
| Rewards, weather, soundspace, profile, settings, notifications | `lib/features/lifestyle/mlp_lifestyle_pages.dart` | External capabilities labeled unavailable; persisted local preferences |
| Background settings | `lib/features/lifestyle/mlp_background_settings.dart`, `lib/core/design_system/mlp_appearance.dart` | Gallery cancel/error/resize/restart tests; native picker still needs device |
| Shared surfaces, navigation, dialogs, buttons | `lib/core/design_system/mlp_liquid_glass.dart`, `mlp_widgets.dart`, `mlp_reference_components.dart`; `lib/app/theme/mlp_design_system.dart`; `lib/app/mlp_product_shell.dart` | Bounded blur, shared colors, SafeArea, semantics; exceptions below |
| Legacy task/habit forms, review | `lib/demo/demo_app.dart`, `lib/demo/demo_forms.dart`, `lib/demo/demo_review.dart` | Existing CRUD/validation tests retained; no legacy data migration |

## Verified findings before this fix batch

No P0 crash has been reproduced in this audit yet. P1/P2 findings below come from
actual source; status and regression evidence will be recorded in the completed report.

| ID | Severity | Screen / exact file | Finding | Intended solution |
|---|---|---|---|---|
| UI-01 | P1 | Today — `lib/features/workspace/mlp_workspace_pages.dart` `_HabitGlassCard` | Increment/undo await store operations outside `e.act`; write failures escape the UI handler | Use common error feedback for all three controls; celebrate only after success |
| UI-02 | P2 | Today — same file | Main habit control is a 36px GestureDetector without button label/keyboard activation | 48px semantic IconButton with meaningful state-dependent label |
| UI-03 | P2 | All celebration callers — `lib/core/design_system/mlp_confetti.dart` | Animation always runs even with disableAnimations; unbounded badge text can overflow at narrow width/large scale | Static accessible feedback for reduced motion; bounded scrollable badge |
| UI-04 | P2 | Dialogs and secondary routes — `lib/core/design_system/mlp_liquid_glass.dart`, `lib/app/theme/mlp_design_system.dart`, `lib/features/focus/mlp_focus_pages.dart` | Dialog transition and MaterialPageRoute Cupertino transitions ignore reduced motion; custom focus dialog bypasses shared styling; sheet already respects it | Shared dialog wrapper, no-animation modal style and shared reduced-motion transition builder |
| UI-05 | P1 | Desktop web preview — `lib/core/design_system/mlp_device_frame.dart` | Minimum frame height 650 exceeds short browser height; child inherits desktop MediaQuery; decorative island covers content | Fit/fallback at short heights, local viewport and reserved insets, transparent decorative input |
| UI-06 | P2 | Desktop preview — same file | “Apple iPhone 16 Pro Max · iOS 18” falsely implies the web preview identifies an actual device; full-screen toggle has no return control | Neutral preview label and reversible toggle |
| UI-07 | P2 | Today — `lib/features/workspace/mlp_workspace_pages.dart` | Habit AnimatedContainer uses fixed 200ms despite reduced motion | Use shared motion duration |
| UI-08 | P2 | Status documentation — `docs/MPL_DEMO_COMPLETION_REPORT_UZ.md`, `docs/MLP_UI_REMAINING_ISSUES.md` | Unqualified 100%/device-quality claims and stale counts contradict missing native evidence | Add superseding notice and current measured report |
| UI-09 | P1 | Today — `lib/features/workspace/mlp_workspace_pages.dart` | New daily XP caption multiplies focus minutes by 2, whereas `DemoStore.xp` credits one per session minute; the view also excludes goal/check-in awards | Display the authoritative total XP with an explicit total label |
| UI-10 | P1 | Shared floating tabs — `lib/core/design_system/mlp_widgets.dart` | Screenshot review shows the bar centered over content when directly used as `bottomNavigationBar`: its `Center` expands vertically. Production shell's wrapping Column masks this in some contexts | Set heightFactor to shrink-wrap; regress rendered geometry and refresh screenshots |

Already present, requiring regression verification rather than duplicate fixes:
chat uses jumpTo when animation duration is zero; voice exit pops the prior page
instead of pushing another chat; bottom sheet has no-animation style.

## Validation plan and open release gates

- Run `flutter pub get`, `flutter analyze`, full `flutter test --concurrency=1`.
- Extend widget viewport matrix with 360 and 393, safe insets and keyboard;
  retain 320, 430, large text and landscape tests. These simulate layout only.
- Regress chat send with reduced motion, voice return, modal/secondary transitions,
  habit feedback, and confetti large text/reduced motion.
- Widget PNGs under `docs/evidence/sprint01/liquid-glass/` are fixtures, **not native
  screenshots**. New command evidence goes to `docs/evidence/ui-audit-2026-10-28/`.
- Actual Android install, gesture navigation, TalkBack, native gallery/lost picker,
  performance profiling and long lifecycle testing are release gates. Windows
  cannot establish an iOS build/VoiceOver pass. No 60 FPS claim without measurement.
- Data persistence is local; ordinary core CRUD rollback/full bundle restore and
  account isolation remain production work. Live AI/auth/audio/weather/notification
  delivery/payment integrations are not established by attractive UI or passing tests.
