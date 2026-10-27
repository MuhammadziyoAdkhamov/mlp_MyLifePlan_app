# MLP — mavjud arxitektura va boshqariladigan UI kengayishi

Tekshiruv: 2026-10-26. Bu diagrammada faqat topilgan real bog‘lanishlar bor; dotted yo‘llar faol `main.dart`dan ochilmaydigan eski qatlamni ko‘rsatadi.

```mermaid
flowchart TD
  mainEntry["lib/main.dart"] --> preferences["SharedPreferences.getInstance"]
  mainEntry --> demoStore["DemoStore.init"]
  mainEntry --> entryGate["MLPEntryGate: local demo profile restore"]
  entryGate --> uiRepo["MLPLocalUiRepository / mlp_ui_prototype_v1"]
  entryGate --> accounts["Welcome / Demo registration / Login unavailable / Preferences"]
  entryGate --> demoApp["MplDemoApp / Workspace"]
  demoApp --> goalFlow["Custom goal / Clarification / Diagnostic / Roadmap / Detail"]
  goalFlow --> demoStore
  goalFlow --> uiRepo
  demoApp --> calendar["Calendar / Schedule editor / occurrence self-report"]
  calendar --> uiRepo
  calendar --> demoStore
  demoApp --> demoForms["DemoForms: task / habit / goal / proof / check-in"]
  demoApp --> review["DemoReview: local progress and evidence"]
  demoApp --> hub["DemoHub: JSON / CSV / ICS"]
  demoForms --> demoStore
  review --> demoStore
  hub --> demoStore
  demoStore --> localJson["mpl_lifeos_demo_v1 JSON"]
  localJson --> preferences
  demoApp --> localProfile["name and daily capacity preferences"]
  localProfile --> preferences
  legacyEntry["lib/main_legacy.dart"] -.-> riverpod["core/providers + core/router"]
  riverpod -.-> featureScreens["features onboarding / goals / roadmap / lessons / chat"]
  riverpod -.-> separateJson["mlp_user / mlp_goals / mlp_roadmaps"]
  oldRouter["routes/app_router.dart"] -.-> oldState["providers/AppState + screens"]
  oldState -.-> auth["AuthService / Google / FirebaseAuth"]
  oldState -.-> cloud["CloudSyncService"]
  cloud -.-> firestore["Firestore users/uid/app_state + habits"]
  oldState -.-> scopedStorage["LocalStorageService: guest / user scopes"]
  oldState -.-> reminders["NotificationService: mobile local notifications"]
```

Diagrammadagi Firestore real repository adapteri, **live cloud ulanishi tasdig‘i emas**. Faol main Firebase init qilmaydi. `main_legacy` Riverpod app bo‘lib, eski `AppRouter/AppState`ni o‘zi ishlatmaydi.

## Papka va xizmat majburiyatlari

- `lib/main.dart`: Flutter binding, local preferences va demo store bootstrap. Initial init xatosiga UI hozir yo‘q.
- `lib/demo/demo_app.dart`: faol theme, adaptive shell, Bugun/Reja/Fokus/sozlamalar, app lifecycle va aktiv taymer. Business qoidalari ko‘pi store’da; root katta, yangi modullar shu faylga tiqilmasin.
- `lib/demo/demo_store.dart`: mavjud local repository + domain service + ChangeNotifier vazifasini birga bajaradi. JSON schema, validation, atomic import, persisted aggregate va hisoblashlar shu yerda.
- `lib/demo/demo_forms.dart`: input validation, busy/save/error, tasdiq va controller disposal. Mavjud formalar yangi oqimda qayta ishlatiladi.
- `lib/demo/demo_review.dart`: source-state asosida review, portfel va eksport. `_WeekStats` tarixiy habit rule bilan moslanishi kerak.
- `lib/core/design/`, `core/widgets/`: oldingi navy/violet theme va reusable UI. Yangi markaziy MLP token/widget qatlamini shu yaxshi tajribadan kengaytirish mumkin.
- `lib/core/domain/`, `core/providers/`, `core/router/`, `features/`: Riverpod/go_router prototipi; yangi UI bilan parallel data yozdirilmasin.
- `lib/models/`, `providers/`, `routes/`, `screens/`, `services/`, `widgets/`: legacy habit/auth/cloud qatlam. Ishlaydigan helperlarni o‘chirmasdan saqlash; real adapterlar faqat aniq integration boundary orqali qayta ishlatiladi.
- `firestore.rules`: uid ownership source rule. Deploy va anonymous/cross-user emulator test isboti hali yo‘q.
- `android/`: Java17 compile/desugaring, notification receiverlar, conditional release signing. Joriy Gradle runtime loopback xatosi platform gate.
- `test/`: store invariants, import/export, forms/navigation/focus widget va render tekshiruvlari.

## Asosiy mavjud domenlar

| Model | Ma’no va muhim invariant |
|---|---|
| DemoGoal | Erkin title, numeric metric/target/current, deadline/category; current self-report, title emas sertifikat |
| DemoTask | Project, minutes, priority, dueDate, nullable goalId; proof/URL/completedAt; completion idempotent XP |
| DemoHabit | Target/unit/weekdays, per-day logs/reasons; historyRules tahrirdan oldingi kun ma’nosini saqlaydi |
| FocusRecord | Nullable taskId, real active seconds, timestamp; bu o‘qish natijasi emas |
| DailyCheckin | Kun, mood/energy 1–5, note; bitta kun yangilanishi qayta XP bermaydi |
| Legacy MlpGoal/MlpRoadmap | Yangi demo domenidan boshqa schema; tasodifan interchange qilinmasin |

## Mavjud oqimlar

1. Bootstrap → prefs → DemoStore.init: saved valid JSON → restore; key yo‘q → belgilangan sample; corrupt → raw data saqlanadi, xato yuzaga chiqadi.
2. Goal/task/habit form → validation → store mutation → notify → ketma-ket JSON write. Oddiy mutation uchun write failure memory rollback yo‘q; error/retry bor. Import esa validate → apply → persist → fail bo‘lsa oldingi holatga qaytadi.
3. Fokus: wall clock + anchorElapsed → pause’da real delta → persist FocusRecord → vazifa alohida proof orqali tugaydi. Process death’da pending timer tiklanmaydi.
4. Analytics: self-report tasks, habit logs, active seconds va manual goal metric. Independently assessed skill modeli hali yo‘q. Faollikning XP/darajasi malaka reytingi emas.
5. Eksport/import: manual JSON round-trip, CSV/ICS matn almashish, clipboard report. OAuth/sync emas; hech kimga avtomatik xabar ketmaydi.

## Saqlab qolish kerak bo‘lgan komponentlar

DemoStore validation/JSON contract va tests; Goal CRUD va link counters; DemoForms error/busy/controller lifecycle; focus wall-clock mexanizmi va uning 45 sekund testi; safe CSV/ICS escape/folding; destructive confirmation/import rollback; legacy uid storage va ownership rule; timezone notification adapterining mavjud platform boundarysi. Ekranlarni bir kechada o‘chirib, yangidan framework qurish talab qilinmaydi.

## Maqsadli UI o‘zgarishi

Yangi master prompt bo‘yicha nazoratli kengayish:

```mermaid
flowchart LR
  tokens["MLP design tokens and shared widgets"] --> appShell["MLP app shell and named routes"]
  appShell --> existingCore["Existing DemoStore and proven forms/focus"]
  appShell --> uiModules["Onboarding / goals / planner / companion / profile"]
  uiModules --> contracts["Small repository interfaces"]
  contracts --> localAdapters["Deterministic local demo adapters"]
  contracts -.-> laterAdapters["Later backend/platform adapters - unavailable until wired"]
  localAdapters --> supplementalState["Versioned supplementary preferences, old data preserved"]
```

- Brend **MLP**, markaziy navy/violet/turquoise tokenlar; floating tablar Bugun/Maqsadlar/Fokus/Ustoz/Profil.
- Mavjud DemoStore bilan yangi schedule/assessment/chat/preferences/reward state orasida aniq boundary; yangi modullar eski kalitlarni o‘chirmaydi.
- 28 ekran named navigation orqali topiladi; hidden/dead CTA bo‘lmaydi. Integratsiya yo‘q bo‘lsa aniq unavailable/preview holati.
- Diagnostic deterministic test yoki self-assessment sifatida nomlanadi. AssessmentResult, reported Task proof va FocusRecord alohida ko‘rsatiladi.
- Voice listening/thinking/speaking — demo UI; real mikrofon/STT/TTS ruxsati olinmagan bo‘lsa “yozilyapti” degan soxta da’vo yo‘q.
- Weather/audio/partner reward faqat preview yoki licensed/local asset bo‘lsa real playback; yo‘q narsaga play/sotib olish success ko‘rsatilmaydi.
- Naviyatsiya/UI migratsiyasi bosqichma-bosqich; phase checkpointlarda faqat xavfsiz allowlist commit. Kalit/config/secrets commitga kiritilmaydi.

## Sinov strategiyasi

Phase B checkpoint: active main onboarding default yoqilgan. Eski widget harness explicit `enableOnboarding: false` bilan saqlanadi. UI repo profile/preferences/goal metadata uchun commit-before-notify qiladi; eski kalitlarni o‘zgartirmaydi. `DemoStore.addGoalPlan` bir goal va uning tasklarini bitta JSON yozuvda saqlaydi, xatoda yangi yozuvlarni qaytaradi va parallel mutation/resetni vaqtincha to‘sadi. Oddiy legacy mutation rollback muammosi alohida ochiq qoladi. 78 test va analyzer dalili QA hisobotida.

1. Har phase’da mos store/unit invariantlar; real disk rad etishi, JSON version/restore va xato holatlari uchun test.
2. Named route/back, form keyboard/validation/loading/error va end-to-end demo oqimi widget testlari.
3. Viewportlar: 320/360/390/430 kenglik, landscape, 1.0/1.5/2.0 text scale va keyboard inset. Reduced-motion va semantics/touch targetlar tekshiriladi.
4. Screenshot widget render alohida yorliq bilan; real Android screenshot deb berilmaydi. Font/ikon fixture cheklovi QA’da ko‘rsatiladi.
5. Auth/cloud yoqilishidan oldin Firebase emulator’da signed-out/owner/other-uid isolation va delete tests; hozir production Firebase’ga mutation yo‘q.
6. Android smoke gate: yangi APK o‘rnatish, cold/relaunch, guest → goal → task → reminder preference → focus → proof → progress, denied notification permission va process death. Qurilma yo‘q bo‘lsa gate **NOMA'LUM**, green deb belgilanmaydi.
7. Test logs va command exitlar `docs/evidence/`da; `flutter analyze` faqat static sifat isboti.

## 2026-10-27 — birlashtirilgan UI arxitekturasi

```mermaid
flowchart TD
  Boot[MLPBootstrap: load / retry] --> Entry[MLPEntryGate]
  Entry --> Account[Welcome / demo account / preferences]
  Entry --> Shell[MLPProductShell: nested Navigator]
  Shell --> Tabs[Bugun / Maqsadlar / Fokus / Ustoz / Profil]
  Shell --> Routes[Planner / assessment / passport / lifestyle / settings]
  Tabs --> Env[MLPEnvironment]
  Routes --> Env
  Env --> Focus[MLPFocusController: actual clock / lifecycle pause]
  Focus --> Core[DemoStore: goals / tasks / habits / focus / checkin]
  Env --> UI[MLPLocalUiRepository: profile / plans / schedules / chat / tests / choices]
  Env --> Mock[MLPDemoAssistant: deterministic local response]
  Core --> K1[SharedPreferences mpl_lifeos_demo_v1]
  UI --> K2[SharedPreferences mlp_ui_prototype_v1]
  Shell --> Legacy[Preserved Workspace: full CRUD / JSON / CSV / ICS]
  Legacy --> Core
```

`app/mlp_environment.dart` ekranlarga bir xil store, UI repository, focus controller, injected clock va navigation beradi. `app/mlp_product_shell.dart` yagona focus controller yaratadi; tab almashishi taymerni qayta yaratmaydi. Nested route/back handling, missing ID va draft recovery bor. Eski Workspace olib tashlanmagan; Settings/Maqsadlar orqali ochiladi. `main.dart` startup write failure uchun retry UI ko‘rsatadi.

`features/focus`: active seconds uchun wall-clock anchor, monotonic elapsed, lifecycle pause, periodic draft, restartda paused; haqiqiy record idempotent ID bilan, qayd va xavfsiz evidence URL bilan yoziladi. Tanaffus ish soatlariga qo‘shilmaydi. `features/ai_companion`: replaceable assistant interface, deterministic local adapter; context opt-in, tone transforms, persisted atomic conversation pair; voice faqat vizual holatlar. `features/progress`: predefined answer key namuna sinovlari; self-report va faoliyatdan mustaqil. `features/lifestyle`: virtual cosmetics, preview weather, unavailable audio, profile/settings/source notifications.

Yangi domain qo‘shimchalari: FocusRecord optional id/note/evidenceUrl (eski JSON mos), UI focusDraft, chat roles/text/timestamp, predefined-test assessments, favorite IDs, cosmetic selection, city va sound intent. Qo‘shimcha JSONlar init va yozishdan oldin tekshiriladi; yaroqsiz raw saqlov ustidan yozilmaydi. Fokus va maqsad rejasini yangi saqlash rollbackga ega. Eski oddiy core CRUD memory-first cheklovi alohida qayd etilgan.

Full backup export core + UI ni bitta belgilangan bundle ichida beradi. Eski core import alohida saqlanadi; UI bundle import bo‘lmagani aniq ko‘rsatiladi. Maqsad o‘chgan jadval bog‘lanishi editor orqali tuzatiladi. Real notification delivery, network AI/weather/audio/auth adapterlari hozir ulanmagan.

Sinov strategiyasi: core model va export regressiyasi; rejected storage writes/retry; injected clock va idempotency; haqiqiy default entry/goal/focus/report oqimi; route/back, 4 viewport, katta matn/keyboard; real-font widget PNGlari; alohida web compile/runtime va Android device gate. Analyzer natijasi runtime isboti sifatida ishlatilmaydi.
