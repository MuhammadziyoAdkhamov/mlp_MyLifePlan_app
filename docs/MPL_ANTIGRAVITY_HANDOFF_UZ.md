# ANTIGRAVITY uchun MPLni shu joydan yakunlash topshirig‘i

**Eng so‘nggi yangilanish:** yo‘riqnoma yozilgach web jarayoni muvaffaqiyatli yakunlandi: `flutter build web --release --no-pub --no-wasm-dry-run` → exit **0**, `Built build/web`, kompilyatsiya **136.5 s**. Quyidagi “web hali ishlamoqda” qaydi oldingi kuzatuv; uni ushbu natija almashtiradi. Endi webni boshidan qayta build qilishdan oldin mavjud `build/web`ni lokal server orqali ochib tekshir. Android APK natijasi hali alohida tasdiqlanishi kerak. Jonli brauzer tekshiruvi va uchta style lint qolgan.

## Vazifa va qat’iy ustuvorlik

Mavjud Flutter loyihani **bugun topshiriladigan, ishlaydigan demo** holatida yakunla. Loyiha boshidan yozilmasin, boshqa frameworkka ko‘chirilmasin. Yangi katta funksiya, backend, haqiqiy AI, OAuth, to‘lov, market va HR integratsiyasi hozir qo‘shilmasin. Eng muhim ish — tayyor funksiyalarni yakuniy tekshirish, build olish, ochib ko‘rsatish va topshirish.

Foydalanuvchi auditoriyani tasdiqlagan: **talabalar va junior mutaxassislar**. Mahsulot sikli: **maqsad → bugungi aniq ish → fokus → natijani topshirish → haftalik ko‘rib chiqish**. Rasmlardagi Balance’dan loyiha/vaqt hisobi, LifeOS’dan boshqaruv ekrani yo‘nalishi olindi. Soxta biometrika, “AI ulangan” yoki “mentor tasdiqlagan” ko‘rsatkichlar bo‘lmasin.

Foydalanuvchining so‘nggi talabi: limit kam, bugun topshirishi kerak. Har muhim yangilanishda demo uchun bajarilgan foizni ayt; tekshirilmagan buildni 100% deb atama. Oxirgi xabar qilingan holat **80%**, qolgan qismi build, jonli tekshiruv va topshirish. Bu biznesning unicorn bo‘lish ehtimoli yoki investitsiya tayyorgarligi foizi emas.

Ishchi papka:

```text
C:\Users\TheMillionaire\Downloads\MY_QUESTs\habit_tracker_GOAL\mylife_plan_guest_mode_fixed_1
```

## 1. Avval hozirgi ishni saqla va holatni tekshir

Repo juda ko‘p **avvaldan mavjud commit qilinmagan foydalanuvchi o‘zgarishlari** bilan kelgan. `git reset --hard`, `git clean`, eski fayllarni ommaviy o‘chirish, barcha o‘zgarishlarni qaytarish ishlatilmasin. Firebase kalitlari/config mazmuni log yoki taqdimotga chiqarilmasin. Hech narsa tashqariga yuborilmagan/publish qilinmagan.

```powershell
Set-Location -LiteralPath 'C:\Users\TheMillionaire\Downloads\MY_QUESTs\habit_tracker_GOAL\mylife_plan_guest_mode_fixed_1'
git status --short
Get-Content docs/MPL_DEMO_ACCEPTANCE.md -Encoding UTF8
```

`docs/MPL_IMKONIYATLAR_TAHLILI_UZ.md` va oldingi `MLP_*` auditlar boshlang‘ich holatni tasvirlaydi. Ularning “145 xato” xulosasi hozirgi yangi demo holati emas. Quyidagi yangi fayllar va qayta tekshiruvlar authoritative hisoblanadi.

## 2. Nima allaqachon yozilganini bilib ol

- `lib/main.dart` — **hozirgi yangi demo entrypoint**. SharedPreferences → DemoStore.init → MplDemoApp. Firebase init va login kerak emas.
- `lib/main_legacy.dart` — avvalgi main nusxasi. Default demo o‘rniga tasodifan ishga tushirilmasin.
- `lib/demo/demo_app.dart` — yangi responsive shell, Bugun, Reja, Fokus, sozlamalar, kunlik sig‘im. Katta ekranda sidebar, telefonda 5 tab.
- `lib/demo/demo_store.dart` — vazifa/dalil, odatlar va kunlar jadvali, maqsad, fokus, kayfiyat/energiya/qayd, XP, tarix, alohida local persistence, JSON import/export.
- `lib/demo/demo_forms.dart` — 7 ta modal oqim: task, habit, goal, submit, checkin, goalProgress, skip. Task/habit/goal’da `existing:` orqali tahrirlash bor.
- `lib/demo/demo_review.dart` — DemoReview, DemoHub va DemoExports. Haqiqiy saqlangan ma’lumotdan statistika, dalillar portfeli, CSV/ICS/JSON matn eksporti, JSON tiklash, mentor hisoboti nusxasi, takror qo‘shilmaydigan 7 kunlik junior shabloni.

Amalda yozilgan oqimlar:

1. Vazifa yaratish/tahrirlash/o‘chirish; loyiha, muddat, daqiqa, ustuvorlik, maqsadga bog‘lash; ertaga ko‘chirish.
2. Kamida 10 belgilik natija matni va ixtiyoriy http(s) havola; bo‘sh/noto‘g‘ri inputni tekshirish. Bu **self-report**, avtomatik tasdiq emas.
3. Bir vazifaga qayta XP bermaslik; reopen XPni qaytaradi; keyingi ochiq ish chiqadi.
4. Miqdorli odat, birlik, hafta kunlari, +1, bugungi qiymatni undo, tanaffus sababi, jadvalga mos streak va 7 kunlik kataklar.
5. Odat tahririda oldingi yozilgan kunlarning target/unit/schedule ma’nosini saqlaydigan `historyRules` snapshotlar bor.
6. Maqsadning sonli natijasi **qo‘lda** yangilanadi. Bog‘langan vazifalar bajarilishi alohida hisoblanadi; ularni bir xil o‘lchov deb ko‘rsatma.
7. Fokus: vazifani tanlash, 25/50/5 daqiqa va 1 daqiqalik haqiqiy sinov, start/pause/resume/reset/save. Vaqt DateTime farqidan hisoblanadi, faqat aktiv vaqt saqlanadi; fon rejimida pauza.
8. Review: real 7 kunlik fokus, weeklyReview, odat bajarilishi, topshirilgan dalillar, XP va streak.
9. JSON zaxira/tiklash: schema va format tekshiruvi, noto‘g‘ri importda eski holat o‘zgarmaydi. CSV formula injection’dan himoyalangan; ICS UTF-8 75-octet folding va all-day sana bilan.
10. Ism va kunlik vaqt sig‘imi, namuna yuklash, tasdiqlab tozalash. Yangi demo ma’lumoti eski MPL hisoblariga tegmaydi.

Saqlash kalitlari:

- asosiy demo: `mpl_lifeos_demo_v1`;
- ism: `mpl_demo_name`;
- kunlik daqiqa sig‘imi: `mpl_demo_daily_budget`;
- eski `mlp_*` va `mylife_plan_app_data_*` ma’lumotlari boshqa tizim, tegilmagan.

API nozikliklari:

- `DemoStore.dayKey(date)` **static**.
- `MplDemoApp`da test uchun `clock:` ixtiyoriy parametr mavjud; prod default DateTime.now.
- `DemoHub(onDataReplaced:)` importdan keyin root fokusini reset qiladi; callback ulangan.
- `DemoHabit.targetForDate(date)`, `unitForDate(date)`, `scheduledOn(date)` tarixiy ta’rifni hisobga oladi. Root UI shu helperlarni ishlatadi.
- `retrySave()` mavjud. Saqlash xatosi ko‘rsatiladi; oddiy mutatsiyalar xotirada qolishi mumkin, barcha mutatsiyalar uchun tranzaksion rollback yo‘q. Yangi katta storage rewrite qilma; xatoni yashirma.

## 3. Davom etayotgan buildni avval tekshir — qayta ko‘r-ko‘rona boshlama

Handoff yozilayotgan paytda quyidagi jarayonlar **haqiqatan tirik**, yakuniy muvaffaqiyat tasdiqlanmagan:

### Web

```text
flutter build web --release --no-pub --no-wasm-dry-run
Codex tool session: 82850
Dart flutter_tools build web PID: 17856 (qayta tekshir)
Log: build/mpl_web_build.log
```

Log oxirgi kuzatishda hali bo‘sh edi. `build/web/index.html` yaratilishi build tugaganini bildirmaydi. `main.dart.js`, assets va successful exit kerak.

### Android debug APK

```text
flutter build apk --debug --no-pub
Codex tool session: 66328
Gradle daemon PID: 12276
Gradle wrapper PID: 22908
Log: C:\Users\TheMillionaire\.gradle\daemon\8.14\daemon-12276.out.log
```

Oxirgi kuzatishda Gradle CPU sarfi ortgan, xato qaytmagan, build tugamagan. Ushbu Codex tool sessionlar boshqa agent dasturida mavjud bo‘lmasligi mumkin; PowerShell jarayon va fayl holatini tekshir.

```powershell
Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('dart.exe','java.exe') } | Select-Object ProcessId,ParentProcessId,CommandLine
Get-Content build/mpl_web_build.log -Tail 25
Get-Content 'C:\Users\TheMillionaire\.gradle\daemon\8.14\daemon-12276.out.log' -Tail 25
Get-Item build/web/main.dart.js,build/app/outputs/flutter-apk/app-debug.apk -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

**Juda muhim:** mavjud `build/app/outputs/flutter-apk/app-debug.apk` oxirgi tekshiruvda **2026-10-10 22:10:27**, **167940627 bayt** edi. Bu **ESKI APK**. Uni yangi demo deb topshirma. Yangi APK build muvaffaqiyati va yangi timestamp tasdiqlansin.

`android/app/google-services.json` mavjudligi tekshirildi, mazmuni chiqarilmagan. Android config o‘zgartirilmadi; offline yangi main Firebase ishga tushirmaydi. Firebase config yetishmasa yoki plugin talab qilsa, Google services plugin apply’ni fayl borligiga shartlash mumkin; buning uchun backendni ulash kerak emas. Release signing yoki Play Store hozir shart emas.

Jarayon hali ishlayotgan bo‘lsa unga imkon ber; ketma-ket yana build boshlab resursni band qilma. Jarayon yakunlangan/mavjud emasligi tekshirilgandagina kerakli buildni qayta ishga tushir.

## 4. Uchta qolgan lintni tozala

Eng so‘nggi to‘liq `flutter analyze --no-pub`da **0 error, 0 warning, 3 info** bor edi (`build/mpl_final_analyze.log`). Keyin root UI tahrirlari bor; qayta tekshirish zarur.

Aniq qolganlar:

1. `lib/demo/demo_store.dart`: weeklyReview ichida `if (...) done++;` uchun `{ }` qo‘yish. Oldingi satr 883; satrlar siljishi mumkin.
2. `test/demo_visual_test.dart`: ortiqcha `dart:typed_data` importini olib tashlash (`flutter/services.dart` ByteData’ni eksport qiladi).
3. `test/demo_widget_test.dart`: `_FailingDemoStore(SharedPreferences prefs) : super(prefs);` ni `_FailingDemoStore(super.prefs);` shakliga o‘tkazish yoki analyzer tavsiya qilgan super parametr.

Funksiyani o‘zgartirma; keyin:

```powershell
dart format lib/demo lib/main.dart test/demo_store_test.dart test/demo_store_edit_test.dart test/demo_export_test.dart test/demo_widget_test.dart test/demo_visual_test.dart
flutter analyze --no-pub
flutter test --no-pub
```

Exit code va aniq natijani yoz. `; Get-Content ...` bilan o‘ralgan shell buyrug‘ining oxirgi exit kodi Flutter muvaffaqiyati deb olinmasin; Flutter exit kodini darhol `$LASTEXITCODE`dan tekshir.

## 5. Mavjud test dalillari va oxirgi umumiy tekshiruv

Quyidagi guruhlar alohida muvaffaqiyatli o‘tgan:

- Eski baseline testlar: **23/23**.
- `test/demo_store_test.dart` + `test/demo_store_edit_test.dart`: **20/20**.
- `test/demo_widget_test.dart`: **8/8**. Desktop1440/mobile390 barcha 5 bo‘lim; form validation/proof/URL/XP; odat undo; tozalash tasdig‘i/eski kalitlarni saqlash; edit; xatoda matnni saqlash; fokus 30 sekund + 5 minut pauza + 15 sekund → **45 aktiv sekund bir marta**.
- `test/demo_export_test.dart`: **6/6**. CSV, ICS, report, 360px Review/Hub, starter confirm/dublikat, import invalid va success callback.
- `test/demo_visual_test.dart`: **2/2**, 1440×900 va 390×844 render. Log `build/mpl_visual_test.log`.

Bu **bitta so‘nggi to‘liq suite yugurishi emas**. Yakuniy `flutter test --no-pub`ni bir marta bajar va haqiqiy jami natijani qayd qil. Eski “145 error” baseline endi tuzatilgan: dependencylar qo‘shilgan, Riverpod legacy import moslangan, local storage fixture expected xatosi tuzatilgan.

## 6. Eng muhim qolgan ish — jonli ko‘rinishni tekshir

Codex browser automationida Chrome ham, ichki brauzer ham mavjud emas edi; shu sabab **jonli brauzer tekshiruvi bajarilgani da’vo qilinmaydi**. Widget testlar interaktiv oqimni qopladi, lekin bu production web buildni brauzerda ochish o‘rnini bosmaydi.

```powershell
flutter run -d chrome --web-port 5211
```

Yoki web build tugagan bo‘lsa aynan release artefaktni tekshir:

```powershell
python -m http.server 5211 --bind 127.0.0.1 --directory build/web
```

Keyin `http://127.0.0.1:5211`ni och. 1440×900 va 390×844da:

1. Bugun ochilsin, namuna ma’lumot belgisi ko‘rinsin, matn/tugma/ikonka to‘g‘ri chiqsin.
2. Vazifa yarat, tahrirla, maqsadga bog‘la; bugungi reja va kunlik sig‘im ko‘rinsin.
3. Natija formasida qisqa matnni rad etishini, yetarli matn va haqiqiy formatli URL saqlanishini tekshir.
4. Bir vazifani topshirgach keyingisi ishlasin; XP qayta bosishda oshmasin.
5. Odat +1/undo, dam kuni va tarixiy target/unit mosligini tekshir.
6. 1 daqiqalik haqiqiy sinov fokusini boshlat; kamida bir necha real sekund, pause/resume va saqlashni ko‘r. Tab/fon almashtirishda vaqt qo‘shilib ketmasin.
7. Natijalar, 7 kunlik chart, topshirilgan matn/havola chiqsin.
8. JSON eksport → o‘zgarish → import tiklash; xato JSON eski holatni saqlasin. Import root fokusini reset qilsin.
9. Reload qilinganda saqlangan ma’lumot qaytsin. **Saqlanmagan fokus sessiyasi reload’da tiklanmaydi**; bu cheklov fokus sahifasida yozilgan.
10. Tozalashni avval cancel, keyin disposable demo/zaxira bor holatda confirm qilib tekshir; eski MPL hisoblari o‘chmasin.

Avtomatik render rasmlari:

```text
build/mpl_preview/today-1440.png
build/mpl_preview/today-390.png
```

**Rasmlar haqida:** test muhiti button default font va MaterialIconsni to‘liq yuklamagani uchun ayrim ikonka kvadrat, FilledButton matni qora blok bo‘lib render bo‘lgan. Buni production ham buzilgan deb yoki production yaxshi deb taxmin qilma. Jonli buildni ko‘r. Agar jonlida to‘g‘ri bo‘lsa faqat visual testning font setup’ini to‘g‘rila; font/ikonka yuklab olinishini testda ta’minla. Ishchi demo uchun yon ta’sirli font rewrite shart emas. Internetdan foydalanmaydigan birinchi yuklash talab qilinsa CanvasKit/font resurslarini ham lokal qilish alohida tekshirilsin; faqat local storage borligi cold-start offline web isboti emas.

Ma’lum kichik yakunlash bandlari:

- Ism tozalangandan so‘ng root shu sessiyada “Foydalanuvchi”, keyingi fresh init’da default “Muhammad” chiqishi mumkin. Defaultni “Foydalanuvchi” qilib izchil qil; namuna bilan ism ko‘rsatish kerak bo‘lsa faqat sample holatida.
- `kun ritmi` foizi engine’da 70% rejalangan amallar + 20% fokus + 10% kunlik check-in. UI’da qisqa tooltip izohi berish foydali; uni klinik diqqat/flow o‘lchovi deb ko‘rsatma.
- Review hozir hisoblangan qoidali weeklyReview va portfelni beradi; alohida haftalik refleksiya formasi yozilmagan. Kunlik checkin note mavjud. Bugungi topshirish uchun buni ochiq cheklov deb qayd etish mumkin; zarur bo‘lsa yangi backend o‘rniga shu qaydni ishlat.
- JSON/CSV/ICS — **nusxalanadigan matn eksporti**, bevosita yuklab olinadigan fayl/OAuth sync emas. UI buni tushuntiradi. Taqdimotda “Notion ulandi” deyilmasin.
- `web/index.html` va `web/manifest.json`da eski umumiy nom/description va Flutter-ko‘k theme rang qolgan. Xavfsiz bo‘lsa MPL nomi/description/qorong‘i theme rangga mosla; bu release build qayta yaratilishini talab qiladi.
- Release/web va APK eski bo‘lmasin: oxirgi kod o‘zgarishidan keyingi buildni tekshir. Lint-only test o‘zgarishi uchun binaryni qayta qurish shart emas; prod kod o‘zgarishi uchun kerak.

## 7. Topshirish paketi va ishga tushirish yo‘li

Minimal topshiriladigan narsalar:

- Yangi demo ochiladigan lokal URL va/yoki yangi debug APK.
- Muvaffaqiyatli web release build bo‘lsa `build/web/` katalogi zip ko‘rinishida; serverdan ochish kerakligini tushuntir. `index.html`ni double-click qilib `file://` orqali ochish mos ishga tushirish yo‘li emas.
- Haqiqiy yangi `app-debug.apk` bo‘lsa nomini `MPL-demo-2026-10-19.apk` kabi ajratib nusxala. Eski APKni ishlatma.
- `docs/MPL_MARKET_STRATEGY_UZ.md` — 13 raqib, manbalar, 22/100 mezonlari, integratsiya va 90 kunlik validatsiya.
- `docs/MPL_INVESTOR_BRIEF_UZ.md` — qisqa konsept, ichki draft; hech kimga yuborilmagan.
- `docs/MPL_DEMO_ACCEPTANCE.md` — G1–G10 tekshiruv bandlari. Faqat isbotlanganlarini yop; bozor intervyusi, retention, to‘lov hali haqiqiy dalilga ega emas.
- Qisqa README: run, qaysi platformada tekshirildi, local data/backup va backend keyin ekani.

Backend yoki production hostingni bugun majburan qo‘shma. Web build muhitda tiqilsa jonli `flutter run -d chrome` orqali ishlaydigan demo ham topshirish yo‘li bo‘la oladi; buni release tayyor deb atama. Agar APK environment muammosiga uchrasa ishlaydigan web demoni kechiktirma, muammoni aniq yoz.

## 8. 90 soniyalik ko‘rsatish ssenariysi

1. “MPL talaba va juniorning rejasini ko‘rinadigan ishga aylantiradi.” Bugun ekranini och.
2. “Portfolio uchun login formasini yozish” kabi bitta vazifa yarat; muddat/25 daqiqa/maqsad bog‘lanishini ko‘rsat.
3. Fokusni boshlat, pause va haqiqiy saqlangan sekundni ko‘rsat; 25 minut bajarildi deb soxtalashtirma.
4. Natijaga nima chiqqanini yoz, GitHub yoki hujjat havolasini ixtiyoriy kirit; topshir.
5. Natijalar portfelida yozuv, progress va fokusni ko‘rsat.
6. Odat uchun +1 qil, jadval va qaytarishni ko‘rsat.
7. Markazda zaxira yoki mentor hisobotini och: “Hozir manual eksport, avtomatik integratsiya keyingi bosqichda.”
8. Investor uchun yakun: “Keyingi isbot — 20 foydalanuvchi va 2 mentor bilan 30 kunlik pilot.” Bu reja, mavjud traction emas.

Investor saralashidan o‘tish, angel investitsiya va unicorn natijasi kafolatlanmaydi. Demo tayyorligi foizi bilan bozorning tekshirilgan bahosi aralashtirilmasin. Boshlang‘ich **22/100** rubric hujjatda bor; yangi demo texnik sifatni yaxshilaydi, lekin real foydalanuvchisiz retention/monetizatsiya ballari o‘z-o‘zidan oshmaydi.

## Tugatish sharti

Yangi funksiyalarni ko‘paytirmasdan: analizni tozala → testlarni to‘liq o‘tkaz → yangi buildni tasdiqla → real ekranda asosiy oqimni tekshir → to‘g‘ri artefakt va 90 soniyalik ssenariyni topshir. Tekshirilmagan bandlar aniq yozilsin. Bugungi maqsad — ishonchli demo va halol taqdimot.
