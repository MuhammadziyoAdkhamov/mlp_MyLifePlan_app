# MLP — beta va to‘liq UI ishlar taxtasi

2026-10-26; filial `feat/mlp-beta-sprint01`. Yangi master prompt Phase A–F doirasini boshqaradi. Avvalgi Day-1 hisobotlari saqlanadi; UI birinchi yaxshilanishdan keyin to‘xtamaydi. Hamma talab uchun source, test va QA dalili kerak. Rejalashtirilgan ekran tayyor deb hisoblanmaydi.

## Bajarish qoidasi

- Eski ekran/fayl/data/config o‘chirilmaydi; dependency major upgrade va production backend bu sprintda yo‘q.
- Har chipta kichik source change va o‘ziga tegishli test bilan yopiladi. Keyingi chiptaga o‘tish avvalgisini yashirish degani emas.
- `ISHLAYOTGAN` widget testi fizik Android runtime isboti emas. Android gate UI bilan parallel bloklangan holatda ochiq turadi.
- Phase’lar barqaror bo‘lganda xavfsiz commit; pre-existing staged delete va user work hech qachon tasodifan bitta umumiy `git add .` bilan olinmaydi.

## A — audit va poydevor

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| A01 / P0 | Joriy audit, architecture, sprint board | Real entrypoint/source, 10 nuqson, commands, secretsiz dalil; xavfsiz branch | `flutter doctor -v`; `flutter pub get`; `flutter analyze --no-pub`; `flutter test --no-pub` | Hisobotlar yozildi; 59 test/static clean; Android bloklangan |
| A02 / P1 | `.gitignore` encoding/patternni tiklash; A01 | NUL yo‘q; Firebase/signing exclusion saqlangan; main/README/demo kod ignore emas | `git check-ignore --no-index`: 4 positive + 4 negative, evidence saqlandi | Bajarildi |
| A03 / P1 | MLP tokenlar va reusable components; A02 | Palette/spacing/type/radii/durations bitta qatlamda; reduced-motion; form/button/card semantics | Design-system widget tests; analyzer | UI checkpoint bajarildi; Phase F QA qolgan |
| A04 / P1 | 28 ekran inventory, route registry, demo interfaces; A03 | Har screen uchun nom/route/holat; unknown route fallback; old store saqlangan | Route inventory tests | Registry bor; dispatch C01da |
| AND01 / P0 | Android build muhitini tekshirish; A01 | Loopback sababini logdan aniqlash; secretsiz log; yangi debug build; license qabulini yashirmaslik | `flutter build apk --debug --no-pub`; `adb devices -l` | Build exit 1, qurilma yo‘q |

## B — onboarding va maqsadlar

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| B01 / P1 | Splash/welcome/guest; A04 | Restore → onboarding yoki home; aniq demo mode; guest exit data o‘chirmaydi | Onboarding/guest restart/back widget tests | UI checkpoint bajarildi; Phase F QA qolgan |
| B02 / P1 | Demo registration/login; B01 | Ism/telefon validation; gender cheklovsiz; real SMS success yo‘q; unavailable Google/phone rost yorliq | Invalid input/error/keyboard tests | UI checkpoint bajarildi; Phase F QA qolgan |
| B03 / P1 | Preferences; B02 | Vaqt, soat, notification intent, AI nickname/tone edit va local restart | Prefs persistence tests | UI checkpoint bajarildi; Phase F QA qolgan |
| B04 / P1 | Custom discovery/clarification; B03 | Toifa shart emas, erkin matn; result/date/time/level/why; edit summary; mavjud CRUD qayta ishlatiladi | Goal create/edit/delete/restart tests | UI checkpoint bajarildi; Phase F QA qolgan |
| B05 / P1 | Diagnostic/roadmap/detail; B04 | Bilmayman, deterministic answer/explanation yoki explicit self-assess; editable prototype plan; detail/archive | Diagnostic + roadmap navigation tests | UI checkpoint bajarildi; Phase F QA qolgan |

## C — asosiy mahsulot

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| C01 / P1 | Home va floating 5 tab; B05 | Asosiy vazifa birinchi ko‘rinadi; hafta/date tanlovi, 5-min variant, sig‘im va routes ishlaydi | Home/nav/small-screen tests | Kutilmoqda |
| C02 / P0 | Local schedule repository/editor; C01 | Date/start/end/repeat/goal/task/reminder intent; CRUD; overlap/overload warn; external launch honest state | Recurrence/overlap + form persistence tests | UI checkpoint bajarildi; Phase F QA qolgan |
| C03 / P1 | Calendar today/week/month; C02 | CRUD darhol aks etadi, sana tanlash, seans natijasiga yo‘l | Calendar widget tests | UI checkpoint bajarildi; Phase F QA qolgan |
| C04 / P1 | Focus dashboard/active/summary; C01 | Mavjud real timer saqlanadi; custom duration, break presets, notes/evidence summary; no fake mastery | Focus clock/pause/summary restart tests | Kutilmoqda |
| AND02 / P0 | Haqiqiy task reminder adapter; C02 + AND01 | Ruxsat denied/accepted; cancel/reschedule; boot/timezone siyosati; phone’da yetkazish isboti | Plugin mocks + Android runtime smoke | UI-only demo’dan keyingi platform gate |

## D — ustoz va tekshirish

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| D01 / P1 | USTOZ AI local chat adapter; B05 | Contextual deterministic demo, history/composer/retry/error/clear; no live API claim | Chat input/response/error/persistence tests | Kutilmoqda |
| D02 / P2 | Voice-state UI va personalization; D01 | Listening/thinking/speaking demo controls, mute/end/chat, nickname; fake mic yo‘q; dismissible in-app launcher | State/control/keyboard overlap tests | Kutilmoqda |
| D03 / P1 | Verification va Skill Passport; B05/C04 | Self-report, activity, deterministic test alohida; pass/fail/explanation; no certificate claim | Assessment scoring/portfolio tests | Kutilmoqda |
| D04 / P1 | Review tarixiy rule bug + analytics; D03 | `targetForDate`/`scheduledOn` izchil; barcha raqam source-state; unknown ability empty | History-edit regression + analytics tests | Kutilmoqda |

## E — qo‘llovchi ekranlar

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| E01 / P2 | Virtual rewards/detail; D03 | Earned/locked/available/unavailable/demo; XP creditdan alohida; hamkor logosi/pul va’dasi yo‘q | Reward state tests | Kutilmoqda |
| E02 / P2 | Weather planner preview; C03 | City/today/tomorrow; offline-preview yorliq; activity vaqtini edit qilish; live forecast emas | Preview/reschedule tests | Kutilmoqda |
| E03 / P2 | Soundspace; C04 | Sections/favorites/mini-player/sleep intent; licensed asset bo‘lmasa play aniq unavailable | Audio preview/favorite/timer tests | Kutilmoqda |
| E04 / P1 | Profile/settings/notification inbox; B03/E01 | Har row haqiqiy route/control/unavailable; logout guest; privacy/backup; incoming notifications fake emas | Settings/data control/nav tests | Kutilmoqda |

## F — QA va topshirish

| ID / ustuvorlik | Ish va bog‘liqlik | Qabul mezoni | Tekshiruv | Holat |
|---|---|---|---|---|
| F01 / P1 | Responsive/accessibility matrix; B–E | 28 ekran route/back/main action/states; 320–430px, landscape, keyboard, textscale, reduced motion; overflow yo‘q | Widget + semantics + screenshot tests | Kutilmoqda |
| F02 / P0 | Init/write failure siyosati; A04 | Buzilgan/yozib bo‘lmagan store userga error/retry beradi; false success yo‘q; existing data saqlanadi | Failing storage + bootstrap tests | Kutilmoqda |
| F03 / P1 | Yakuniy QA/reports/phase commit | Inventory QA evidence, design docs, remaining limits; prod capability mockdan ajratilgan | `flutter analyze`; `flutter test`; build va mavjud device smoke | Kutilmoqda |

## Eng yaqin bitta chipta

**C01 — floating shell va flagship Bugun.** Calendar/editor main headerga ulandi; C02/C03 funksional checkpoint 12 test bilan tekshirildi. Hozir jami 12 ekran yozilgan. Bugun/Maqsadlar/Fokus/Ustoz/Profil tartibini to‘g‘ri bo‘limlar bilan ulang; eski Review/Hub/CRUD yo‘llari saqlansin. A04 route registry bor, to‘liq named route dispatch shu shellda yakunlanadi.

Android yopiq beta uchun birinchi release-blocking chipta **AND01** bo‘lib qoladi. License noma’lum yoki loopback xatosi UI mock qo‘shish bilan hal bo‘lgan deb ko‘rsatilmaydi.
