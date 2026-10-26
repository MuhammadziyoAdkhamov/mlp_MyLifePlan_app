# MLP — qayta tekshirilgan boshlang‘ich audit

Sana: **2026-10-26**, Asia/Tashkent. Ishchi nusxa; asosiy commit `b3e199d51ae53413ab59fe1551cb092d5c610d51`. Filial: **feat/mlp-beta-sprint01**. Bu hisobot 19-oktabrdagi audit da’volarini takrorlamaydi: quyidagi buyruqlar qayta bajarildi.

## Ko‘lam va xavfsizlik

Loyiha va uning ota papkalarida qo‘llanadigan `AGENTS.md` topilmadi. README, DEMO_README, pubspec, barcha `lib/` fayllari ro‘yxati, faol va eski entrypointlar, routerlar, store, formalar, xizmatlar, Firebase qoidalari, Android config va testlar tekshirildi. Oldindan ko‘p dirty/untracked fayl hamda **stagingda lib/firebase_options.dart o‘chirilishi** bor. `git switch -c feat/mlp-beta-sprint01` muvaffaqiyatli; reset/clean/stash qo‘llanmadi. Kalit va signing fayllarining mazmuni olinmadi, credentiallar log qilinmadi.

Yangi yuborilgan `MLP — COMPLETE FLUTTER UI/UX IMPLEMENTATION MASTER PROMPT` avvalgi “1-kuni faqat bitta yaxshilanishdan keyin to‘xta” ko‘lamini kengaytiradi: audit avval tugatiladi, keyin A–F UI bosqichlari davom etadi. Ma’lumot xavfsizligi va haqiqiy integratsiyani soxtalashtirmaslik talablari saqlanadi. Rasmiy brend endi **MLP**; eski `MPL` nomlari hali mavjud.

## Haqiqiy bajarilgan tekshiruvlar

| Buyruq | Exit | Haqiqiy natija | Dalil |
|---|---:|---|---|
| `flutter doctor -v` | 0 | Flutter 3.47.0, Dart 3.13.0; Android toolchain’da SDK license status unknown; Windows uchun Visual Studio yo‘q. Exit 0 barcha tekshiruv yashil degani emas. | `evidence/sprint01/flutter-doctor.txt` |
| `flutter pub get` | 0 | Got dependencies; 35 paketda mavjud constraintlarga mos bo‘lmagan yangi versiyalar bor; major upgrade qilinmadi. | `evidence/sprint01/flutter-pub-get.txt` |
| `flutter analyze --no-pub` | 0 | **No issues found**, 109.7 s | `evidence/sprint01/flutter-analyze-baseline.txt` |
| `flutter test --no-pub` | 0 | **59 test o‘tdi**, 12 s; VM/widget test, fizik Android emas | `evidence/sprint01/flutter-test-baseline.txt` |
| `flutter build apk --debug --no-pub` | 1 | **java.io.IOException: Unable to establish loopback connection**, Gradle assembleDebug, 42.3 s | `evidence/sprint01/flutter-build-apk.txt` |
| `adb devices -l` | 0 | Faqat sarlavha: Android qurilma/emulator ulanmagan | `evidence/sprint01/adb-devices.txt` |

`flutter analyse` so‘rovi Flutter’ning rasmiy `flutter analyze` buyrug‘i bilan bajarildi. Natijalar `evidence/sprint01/command-results.txt`da ham saqlangan. `.log` fayllar repo qoidasi bo‘yicha ignored, lekin diskda mavjud. Ularni maxfiy ma’lumotsiz summary bilan birga saqlash kerak.

`build/app/outputs/flutter-apk/app-debug.apk` mavjud, lekin timestamp **2026-10-10**, 167940627 bayt: joriy kod buildining dalili emas. `build/web/main.dart.js` **2026-10-19** nusxasi. 26-oktabrda web qayta build/production brauzer runtime tekshiruvi hali bajarilmadi.

## Xususiyatlar matritsasi

Holatlar: **ISHLAYOTGAN** — quyidagi aniq test doirasida isbotlangan; **QISMAN** — ishlaydigan bo‘lagi bor, butun oqim yo‘q; **BUZILGAN** — qayta namoyish qilingan xato; **YO'QO'YILGAN** — talab qilingan qism faol mahsulotda mavjud emas (diskdagi eski kod o‘chirilgan degani emas); **NOMA'LUM** — runtime/deploy dalili yo‘q. Hech biri o‘z-o‘zidan Android runtime tasdig‘i emas.

| Xususiyat | Haqiqiy fayllar | Holat | Dalil va chegarasi | Ustuvorlik |
|---|---|---|---|---|
| Faol kirish va asosiy UI | `lib/main.dart`, `lib/demo/demo_app.dart` | ISHLAYOTGAN | `MplDemoApp` va SharedPreferences/DemoStore; 5 bo‘lim widget navigatsiya testi; login talab qilmaydi | P1 |
| Aniq guest/onboarding/chiqish | `lib/demo/demo_app.dart`; eski `screens/login_screen.dart` | QISMAN | Faol app mahalliy rejimda darhol ochiladi; alohida welcome/guest session oqimi yo‘q | P1 |
| Google login | `services/auth_service.dart`, `providers/app_state.dart`, `screens/login_screen.dart` | QISMAN | Real Google/Firebase adapter kodi bor, lekin faol main uni yaratmaydi; haqiqiy sign-in tekshirilmagan | P1, cloud yoqilishidan oldin |
| Telefon/SMS OTP | `features/onboarding/onboarding_screen.dart`, `core/providers/app_providers.dart` | YO'QO'YILGAN | Eski telefon maydoni mahalliy profilga yoziladi; `verifyPhoneNumber`/PhoneAuth oqimi topilmadi; SMS tasdig‘i emas | P1 |
| Erkin matnli maqsad CRUD | `demo/demo_store.dart`, `demo/demo_forms.dart`, `demo/demo_app.dart` | ISHLAYOTGAN | add/edit/delete/progress, muddat/o‘lchov; normal persistence va invalid edit/JSON testlari | P1 |
| Vazifa CRUD, goal link, self-report | Shu demo fayllari | ISHLAYOTGAN | Matn min 10 belgi, URL validation, reopen/deferral; qayta topshirishda XP dublikat bo‘lmaydi | P1 |
| Odat jadvali va undo | `demo/demo_store.dart`, `test/demo_store_edit_test.dart` | ISHLAYOTGAN | Rejasiz kunlar, tarixiy target/unit snapshot, +1/undo saqlanishi testlangan | P1 |
| Diagnostika va roadmap | `features/goals/diagnosis_screen.dart`, `core/services/mock_data.dart`, `features/roadmap/` | QISMAN | Eski Riverpod oqimida shablon mavjud; yangi demo navga ulanmagan; diagnostika javobi generatorni moslashtirmaydi | P1 |
| Aqlli kalendar/schedule CRUD | `demo/demo_review.dart`dagi ICS eksport | YO'QO'YILGAN | Kalendar matn eksporti bor; start/end, recurring schedule muharriri va overlap tekshiruvi yo‘q | P0 vertikal bo‘lak |
| Rejalashtirilgan eslatma | `services/notification_service.dart`, eski `providers/app_state.dart` | QISMAN | Timezone/permission/zonedSchedule kodi odatlar uchun bor; faol demo bilan ulanmagan; test faqat parseTime | P0 vertikal bo‘lak |
| Fokus start/pause/resume/save | `demo/demo_app.dart`, `demo/demo_store.dart` | ISHLAYOTGAN | Clock-injected test: 30 s aktiv + 5 min pauza + 15 s aktiv = 45 s; task completion alohida | P1 |
| Fokusni reload/process death’dan tiklash | `demo/demo_app.dart` | YO'QO'YILGAN | Aktiv taymer widget xotirasida; saqlanmagan sessiya tiklanmasligi UI’da aytilgan | P1 |
| Natija dalili/portfel | `demo/demo_forms.dart`, `demo/demo_review.dart` | ISHLAYOTGAN | Self-report va tashqi tasdiq yo‘qligi yozilgan; matn/havola portfeli | P1 |
| Mustaqil/deterministik bilim baholash | `features/learning/learning_screen.dart` | YO'QO'YILGAN | Faol demoda assessment yo‘q; eski dars `_isCorrect`dan qat’i nazar XP beradi | P1 |
| Faollik va maqsad progressi | `demo/demo_store.dart:score`, `demo/demo_app.dart` | QISMAN | Faollik indeksi 70% amallar, 20% fokus, 10% check-in; qo‘lda metric/link task count ajratilgan; malaka bahosi emas | P1 |
| Haftalik odat statistikasi | `demo/demo_review.dart:_WeekStats` | BUZILGAN | Store tarixiy target/schedule ishlatadi, review esa joriy `habit.target`/weekdays; tahrirdan keyin eski natija qayta talqin qilinadi; ushbu holat test bilan hali yopilmagan | P1 |
| Mahalliy saqlash/import/reset | `demo/demo_store.dart` | QISMAN | JSON strict schema/2 MB, invalid import atomik, clear va restore testlari; oddiy mutation disk yozishdan oldin xotirani o‘zgartiradi | P1 |
| Firebase sync va ownership | `services/cloud_sync_service.dart`, `firestore.rules` | QISMAN | Source rule `auth.uid == userId`; faol main cloud ishlatmaydi. Production deploy/emulator isolation dalili yo‘q | P1 cloud gate |
| Deploy qilingan rules | `firebase.json`, `firestore.rules` | NOMA'LUM | firebase.json faqat Flutter platform config; Firestore rules deployment mapping/emulator test yo‘q | P1 cloud gate |
| USTOZ AI | `core/providers/app_providers.dart:ChatNotifier`, `core/services/mock_data.dart` | QISMAN | Eski chat kalit-so‘z skripti; demo belgisi bor; faol demoda chat yo‘q; real API chaqiruvi yo‘q | P1 UI |
| Voice, uyg‘otuvchi so‘z, overlay | Faol fayl yo‘q | YO'QO'YILGAN | Mikrofon/STT/TTS/OS overlay integratsiyasi topilmadi; yangi spec faqat halol voice UI holatlarini so‘raydi | P2 |
| Rewards/weather/Soundspace | `screens/quests_tab.dart`, `portfolio_tab.dart`, `core/services/mock_data.dart` | QISMAN | Eski statik namuna kartalar; real hamkorlik/weather/audio yo‘q; yangi faol oqimga ulanmagan | P2 |
| Git konfiguratsiya himoyasi | `.gitignore` | BUZILGAN | 61 NUL bayt; birikib ketgan pattern; `git check-ignore --no-index lib/firebase_options.dart` mos kelmadi | P1 |
| Android artefakt/runtime | `android/`, build log | BUZILGAN | Yangi APK build exit 1; fizik/emulator runtime dalili yo‘q | P0 beta gate |
| Responsive testlar | `test/demo_widget_test.dart`, `demo_export_test.dart`, `demo_visual_test.dart` | QISMAN | 360/390/1440 viewportlar; keyboard/textscale/landscape va 28 ekran to‘liq qoplanmagan | P1 |

## Eng muhim 10 nuqson

1. **P0 — Android build hozir muvaffaqiyatsiz.** Gradle loopback xatosi; SDK license holati ham noma’lum. Yangi APK va real Android smoke bo‘lmasdan 10–15 kishilik beta tayyor deb bo‘lmaydi.
2. **P0 — schedule → haqiqiy eslatma bo‘lagi uzilgan.** Faol task/goal oqimida reminder field, schedule repository va platform adapter ulanishi yo‘q.
3. **P1 — persistence’ning xato holati to‘liq tranzaksion emas.** Oddiy mutation xotirada oldin bajariladi; initial `DemoStore.init()` disk yozish xatosi `main()`da ekran bilan ushlanmaydi. Error/retry API bor, lekin boshqarilgan yuklash va tiklash UI zarur.
4. **P1 — kirish rejimlari chalkash.** README real Google/cloud deydi, faol main faqat local demo; telefon maydoni SMS emas. Aniq demo/guest entry, privacy va exit talab qilinadi.
5. **P1 — review tarixiy odat ma’nosini buzadi.** `_WeekStats.habitsDone`, `plannedFor`, `doneFor`da store bilan bir xil dated rule ishlatilmaydi. Target/jadval tahriri bilan regressiya testi kerak.
6. **P1 — aktiv fokus saqlanmagan.** Navigationda turadi, process death/reload’da yo‘qoladi; disclosure bor, lekin beta uchun qabul siyosati va summary oqimi kerak.
7. **P1 — uch ajralgan holat/navigatsiya qatlami.** `demo/*`, `core/providers + features/*`, `providers + screens/*` alohida modellar/kalitlar bilan. Eski cloud ma’lumoti avtomatik ko‘chmaydi. Yagona faol appni bosqichma-bosqich kengaytirish kerak.
8. **P1 — `.gitignore` buzilgan.** Firebase client config public identifikatorlardan iborat bo‘lishi mumkin, bu o‘z-o‘zidan private key degani emas; baribir mavjud exclusion niyati bajarilmayapti. Ignore’ni tuzatish tracked tarixni tozalamaydi.
9. **P1 — legacy cloud delete to‘liq emas.** `saveAppData` app_state bilan habits subcollectionga yozadi, `deleteAppData` faqat asosiy hujjatni o‘chiradi. Faol beta local bo‘lsa ishlatilmaydi; cloud yoqilishidan oldin tuzatish va ownership emulator testlari shart.
10. **P2 — hujjat va UI spec mosligi.** README eski entrypointni ta’riflaydi; faol brend MPL, navigatsiya va lime theme yangi MLP/5 tab/navy-violet-turquoise talabiga mos emas. Katta birdan almashtirish emas, markaziy tokenlar bilan nazoratli moslash zarur.

## Minimum vertikal bo‘lak va stop-gate

**Aniq mahalliy mehmon → erkin maqsad → bog‘langan kundalik vazifa → schedule/reminder → fokus → self-report yoki cheklangan deterministik test → halol dashboard.**

- Guest/login: hozir implicit local; yangi UI’da explicit guest/demo kirish qilinadi. Real login faqat existing adapter runtime tasdiqdan keyin.
- Maqsad/vazifa/fokus/self-report: mavjud isbotlangan store va formalar saqlanadi.
- Schedule UI/local recurrence mock: yangi UI bosqichida yoziladi. Platform notification haqiqiy yetkazilishi alohida Android gate.
- Natija: “foydalanuvchi hisobot berdi”, “aktiv vaqt qayd qilindi”, “oldindan berilgan testdan o‘tdi” turli narsa.
- AI: faqat deterministik demo adapter, ochiq yorliq. Haqiqiy voice/wakeword/overlay/music/hamkor redeem bu sprintga qo‘shilmaydi.

Oddiy Goal CRUD, validation va normal restart persistence testlari o‘tdi; “Maqsad CRUD butunlay yo‘q” kabi yashirin core bloker topilmadi. Android build, reminder va disk xato siyosati ochiq to‘siqlar. Dastlab hisobotlar tugatiladi. Keyingi xavfsiz birinchi tuzatish: `.gitignore` encoding/patternni tiklash, `git check-ignore` bilan positive/negative tekshirish. Master prompt keyingi UI bosqichlarini alohida davom ettirishga ruxsat beradi.

## Hisobotdan keyingi birinchi tuzatish — A02

Bajarildi: `.gitignore`dan 61 NUL bayt olib tashlandi va birikkan Firebase patterni alohida satrga tiklandi; app kodi, ekran va saqlangan data o‘zgartirilmadi. 4 positive ignore va 4 negative source visibility tekshiruvi o‘tdi (`evidence/sprint01/gitignore-checks.txt`). Stagingdagi avvalgi `D lib/firebase_options.dart` holati saqlandi. Ignore tracked Git tarixini tozalamaydi va credential audit o‘rnini bosmaydi. Baseline jadvalidagi BUZILGAN holat tuzatishdan oldingi kuzatuv; hozir A02 shu aniq qismni yopdi.

Qayta o‘tkazilgan testlar 59/59; UIning yangi master promptdagi qolgan ekranlari bundan tayyor bo‘lib qolmaydi. `.txt` evidence nusxalari portable saqlangan, asl `.log`lar ham diskda bor.
