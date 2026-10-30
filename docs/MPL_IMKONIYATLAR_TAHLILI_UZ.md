# MPL / MYLife Plan — imkoniyatlar tahlili

Tekshiruv sanasi: 2026-10-19. Manba: aynan shu ishchi papkadagi kod, routerlar, modellar, xizmatlar, dependency ro‘yxati va mavjud testlar. Git tarixidagi boshqa versiyalar yoki telefondagi oldingi APK bu hisobotga kirmaydi.

## 1. Loyiha nima qiladi?

MYLife Plan — shaxsiy rivojlanish ilovasi. Unda ikki asosiy yo‘nalish mavjud: odatlar va intizomni kuzatish; maqsadni o‘quv bosqichlari va vazifalarga ajratish. Rag‘batlantirish uchun XP, daraja, coin, streak va nishonlar ishlatilgan.

Muhim holat: repozitoriyda bir necha avlod interfeys va ma’lumot modeli yonma-yon turibdi. Fayl mavjudligi funksiya hozir foydalanuvchiga ochiq ekanini anglatmaydi. Quyidagi imkoniyatlar kod bo‘yicha aniqlangan; butun ilovaning telefonda ishlashi tasdiqlanmadi, chunki tekshiruvda kompilyatsiya xatolari topildi.

## 2. Hozir ishga tushadigan oqim

`lib/main.dart` → `MlpApp` → `lib/core/router/mlp_router.dart` → `lib/features/...`.

Holat: Flutter + Riverpod + GoRouter + SharedPreferences. Asosiy navigatsiya: **Bugun, Yo‘l xaritasi, Ustoz, Natijalar, Profil**. Kirish oqimi: salomlashish → tanishuv → maqsad → diagnostika → rejani ko‘rish va tasdiqlash → bosh sahifa.

### Tanishuv va profil

- Ism, telefon va ixtiyoriy jins kiritish.
- Qurilmada UUID bilan mahalliy foydalanuvchi yaratish.
- Keyingi ochishda tanishuvdan o‘tilganini eslab qolish.
- Profil ismini tahrirlash; telefon va jinsni ko‘rsatish.
- XP, daraja va coin balansini ko‘rsatish.
- Mahalliy ma’lumotlarni o‘chirish tugmasi mavjud, ammo tozalash to‘liq emas — 6-bo‘limga qarang.
- Telefon raqamini SMS/OTP bilan tasdiqlash yo‘q. Bu haqiqiy autentifikatsiya xizmati emas.

Manbalar: `features/onboarding/onboarding_screen.dart`, `features/profil/profil_screen.dart`, `core/providers/app_providers.dart`.

### Maqsad qo‘yish

- 9 toifa: til o‘rganish, dasturlash, biznes, sog‘liq, moliya, din, sport, ijodiyot va shaxsiy maqsad.
- Kutilayotgan natijani yozish.
- Yuqori, o‘rta yoki past ustuvorlik tanlash.
- Kuniga 15–120 daqiqa vaqt belgilash.
- Bir nechta maqsad saqlash; yangi maqsadni Yo‘l xaritasi bo‘limidan qo‘shish.
- Modelda deadline va joriy daraja maydonlari bor, lekin yangi maqsad formasida ularga alohida boshqaruv berilmagan.
- Maqsadni tahrirlash, o‘chirish yoki arxivlash uchun yangi interfeysda to‘liq oqim topilmadi.

Manbalar: `features/goals/goal_setup_screen.dart`, `core/domain/goal_model.dart`.

### Diagnostika

- Tajriba, kunlik vaqt va o‘rganish uslubi haqida 3 savol.
- Variant tanlash va savollar orasida o‘tish.
- Yakunda yo‘l xaritasi yaratish va 30 XP berish.
- Javoblar vaqtinchalik `_answers` xaritasida turadi. Reja generatoriga uzatilmaydi va alohida natija sifatida saqlanmaydi.
- Shuning uchun bu diagnostika hozir bilim darajasini hisoblamaydi va javoblarga qarab rejani moslashtirmaydi.

Manba: `features/goals/diagnosis_screen.dart`.

### Yo‘l xaritasi

- Bosqichlar, maqsad, baholash mezoni, taxminiy kunlar va vazifalarni yaratish.
- Rejani oldindan ko‘rish, umumiy vaqt/bosqich/vazifalar sonini ko‘rsatish.
- Rejani tasdiqlash va 50 XP olish.
- Tasdiqlangan rejalarni ko‘rish; bosqichlarni ochib-yopish.
- Vazifani bajarildi deb belgilash va unga belgilangan XPni berish.
- Bosqichdagi barcha vazifalar bajarilganda bosqichni tugallangan deb belgilash.
- Til uchun 3 bosqich, 8 vazifa, jami 44 kunlik shablon.
- Dasturlash uchun 2 bosqich, 6 vazifa, jami 35 kunlik shablon.
- Qolgan 7 toifa uchun umumiy 2 bosqich, 6 vazifa, jami 28 kunlik shablon.
- Reja mazmuni `MockData` ichida yozilgan. Natija matni ayrim joylarga qo‘yiladi; kunlik vaqt, ustuvorlik va diagnostika javoblari asosida muddat yoki topshiriqlar qayta hisoblanmaydi.
- Rejani keyin o‘zgartirish haqida matn bor, ammo to‘liq reja muharriri topilmadi.

Manbalar: `core/services/mock_data.dart`, `features/roadmap/`, `core/domain/roadmap_model.dart`.

### Bugun sahifasi

- Vaqtga qarab salomlashish va o‘zbekcha sana.
- Bugun atrofidagi 7 kunlik kalendar tasmasi; sanani tanlab vazifalarni filtrlash ulanmagan.
- Tasdiqlangan rejalardagi birinchi tugallanmagan bosqichning birinchi ochiq vazifasini asosiy vazifa qilib chiqarish.
- Vazifani bajarish yoki shu bosqich darsini ochish.
- Faol maqsadlar va ularning progressini ko‘rsatish.
- AI Ustozga tez o‘tish.
- “Eng muhim” vazifa ustuvorlik yoki muddat bo‘yicha saralanmaydi: ro‘yxatda birinchi topilgani olinadi.

Manba: `features/home/home_screen.dart`.

### Darslar

- Har bir bosqich uchun 2 ta namunaviy dars.
- O‘qish → amaliyot/test → natija oqimi.
- Nazariy matn, amaliy topshiriq va variantli savol.
- Javob to‘g‘ri yoki noto‘g‘riligini ko‘rsatish.
- Birinchi dars uchun 50 XP, ikkinchisi uchun 75 XP; keyingi darsga o‘tish.
- Darslar mavzu nomi o‘zgaradigan umumiy namunalar; alohida fanlar uchun to‘liq kurs kutubxonasi yo‘q.
- Hozir noto‘g‘ri javob ham XP beradi. Darsni qayta ochib mukofotni takror olishni to‘suvchi saqlangan bajarilish belgisi yo‘q.
- Dars yakunlanishi roadmap vazifasini avtomatik tugatmaydi. Video/audio kontent yetkazish va haqiqiy amaliy ishni tekshirish ulanmagan.

Manbalar: `features/learning/learning_screen.dart`, `core/services/mock_data.dart`.

### AI Ustoz

- Xabar yozish, tayyor savollardan foydalanish, javob kutish animatsiyasi, suhbatni yangilash.
- Reja, xato, o‘rganish, vaqt va motivatsiya kalit so‘zlari uchun 5 tayyor javob.
- Mos so‘z topilmasa umumiy javob qaytarish.
- Haqiqiy AI modeli, API chaqiruvi, suhbat kontekstini tahlil qilish yoki fayl/ovoz/rasm bilan ishlash yo‘q.
- Chat xotirada turadi, qayta ishga tushganda tarix yuklanmaydi.

Manbalar: `features/ustoz/ustoz_screen.dart`, `ChatNotifier`, `MockData.aiScripts`.

### Natijalar va rag‘batlantirish

- Bajarilgan va jami vazifalar, tugallangan bosqichlar soni.
- XP, daraja, keyingi darajaga progress va coin.
- XP voqealarini vaqt va sabab bilan tarixga yozish.
- Daraja uchun talab: joriy daraja × 500 XP; daraja oshganda sarflangan XP ayiriladi. Ko‘rsatilgan XP joriy darajadagi qoldiq.
- Har bir mukofot hodisasida `amount ~/ 10` coin beriladi; yaxlitlash har hodisada alohida.
- Yangi modelda streak maydoni bor, uni muntazam yangilaydigan faol mexanizm topilmadi.
- Coin sarflash yoki real mukofotga almashtirish yangi routerga ulanmagan.

Manbalar: `features/natijalar/natijalar_screen.dart`, `core/providers/app_providers.dart`, `core/domain/user_model.dart`.

### Saqlash va tashqi ko‘rinish

- Foydalanuvchi, onboarding belgisi, maqsadlar, rejalar va XP voqealari SharedPreferences ichida JSON sifatida saqlanadi.
- Yangi kod mahalliy rejimga mo‘ljallangan; Firebase ishga tushirilmaydi, Google login va cloud sync ulanmagan.
- Qorong‘i mavzu, animatsiyalar, kartalar, progress indikatorlari va portret yo‘nalish.
- `uz`, `en`, `ru` locale ro‘yxati bor, lekin matnlarning ko‘pi o‘zbekcha qattiq yozilgan; til almashtirish yo‘q.
- Mavzu, til va bildirishnomalar qatorlari “tez kunda” ko‘rinishida, amaliy sozlama emas.

## 3. Eski odatlar tizimida saqlangan imkoniyatlar

Asos: `lib/providers/app_state.dart`, `lib/models/`, `lib/screens/`, `lib/services/`, eski `lib/routes/app_router.dart`.

Bu qismlar hozirgi `main.dart` orqali ilovaga ulanmagan. Ayrim ekranlar eski routerda ham ochilmaydi. Quyidagi ro‘yxat — kodda mavjud mexanizmlar; joriy ishlash kafolati emas.

### Odatlar

- Odat yaratish va o‘chirish; nom, maqsad, toifa, rang/ikonka, boshlanish sanasi.
- 6 toifa: Health, Study, Mind, Faith, Money, Other.
- Har kuni, ish kunlari, dam olish kunlari yoki tanlangan hafta kunlari jadvali.
- Bugun bajarish, bajarilganini qaytarish va sabab bilan o‘tkazib yuborish.
- To‘liq, minimal va recovery bajarish rejimlari.
- Minimal bajarish: odat XP qiymatining 35%i, kamida 8 XP; recovery: 50%i, kamida 10 XP.
- To‘liq kun uchun Perfect Day bonusi; XP tarixi va har 1000 XPga yangi daraja.
- Ketma-ket kunlar, eng yaxshi streak, bajarilish soni, kalendar heatmap.
- Boshlang‘ich fokus: o‘qish/diqqat, quvvat/sog‘liq, xotirjamlik, barqarorlik. Har birida 3 ta tayyor odat taklifi bor.

### Smart Coach va xulq tahlili

- Skip sabablari: charchash, bandlik, unutish, xohlamaslik.
- O‘tkazib yuborishlarning kun/vaqt/sabab bo‘yicha naqshini topish.
- Bajarish paytida 1–5 kayfiyat va energiya qiymatlari.
- Toifalar bo‘yicha kayfiyatga oid oddiy statistik xulosa; bu sabab-oqibatni isbotlovchi tahlil emas.
- Identity votes: har bajarilishni ma’lum shaxsiy rol foydasiga hisoblash.
- Boshlash sababi, accountability hamkorining ismi va majburiyat matnini saqlash/ko‘rsatish. Hamkorga avtomatik xabar yuborilmaydi.
- Habit stacking: keyingi bog‘langan odatni taklif qilish; to‘liq bog‘lash muharriri mavjud emas.
- Bajarilgan ishni vaqt, o‘qish yoki sessiya ekvivalentida ko‘rsatish. Ayrim vaqtlar haqiqiy taymerdan emas, maqsad matnidan taxmin qilinadi.
- Bajarilish vaqtlariga qarab eslatma vaqtini taklif qilish; taklifning o‘zi jadvalni avtomatik o‘zgartirmaydi.
- So‘nggi kunlar o‘tkazib yuborilganda vazifani kichraytirish tavsiyasi.
- Haftalik xulosa, keyingi hafta tavsiyasi va bugungi bitta ustuvor odat.
- Kelajakdagi o‘ziga xat yozish va 30/60/90 kun chegaralaridan keyin ko‘rsatish.

### Natijalar, journey va nishonlar

- Kunlik/haftalik/oylik ko‘rsatkichlar, progress chizig‘i va oylik heatmap.
- Fokus daqiqalari: jami, bugun va odat kesimida; sessiyalarni saqlash modeli.
- 30 kunlik Journey vazifalari va bajarish uchun XP.
- 6 nishon: First Step, 7 Day Streak, Focus Master, Bookworm, Unstoppable, Perfect Week.
- Cheklov: standart Journey ro‘yxatida 7-kundan keyingi vazifalar qulflanadi; ularni keyinchalik avtomatik ochish mexanizmi topilmadi. Focus Master talabi 10 Journey vazifasi bo‘lgani uchun shu standart holatda erishib bo‘lmaydi.

### Hisob, saqlash va eslatmalar

- Guest rejimi va Google orqali Firebase hisobiga kirish kodi.
- Guest va har bir cloud foydalanuvchi uchun alohida mahalliy saqlash.
- Eski ma’lumotni mos foydalanuvchi doirasiga ko‘chirish.
- Guest va cloud ma’lumoti to‘qnashganda cloudni olish, guestni saqlash, birlashtirish yoki bekor qilish tanlovlari.
- Firestorega saqlash/yuklash, sinxronlash holati, hisobdan chiqish.
- JSON eksportini clipboardga nusxalash; demo holatga qaytarish; ilova ma’lumotini o‘chirish.
- Android/iOS uchun vaqt mintaqasini hisobga oladigan mahalliy eslatma xizmati, ruxsat so‘rash, jadval va bekor qilish.
- Web uchun NotificationService eslatma rejalashtirishni qo‘llamaydi. Tashqi push server yo‘q.
- Cheklov: Firestore odatlar subkolleksiyasiga qo‘shimcha yozadi, ammo o‘chirish funksiyasi faqat asosiy app_state hujjatini o‘chiradi; subkolleksiyalar to‘liq tozalanmaydi.

## 4. Lumina / karyera va market prototipi

`LuminaMainScreen` va uning tablari hozirgi asosiy routerga ulanmagan.

- **Fokus:** 25 daqiqalik taymer; ilova inactive/paused bo‘lsa sessiyani bekor qilish; yakunda 5 coin. Bu butun telefondagi boshqa ilovalardan foydalanishni bloklamaydi.
- **QR skaner:** kamera orqali kod topilganda 10 coin berish mexanizmi. QR mazmunini markaz/server ro‘yxati orqali tasdiqlash yo‘q; hozir istalgan o‘qiladigan kod mukofot berishi mumkin.
- **Hamyon:** balans va coin tarixi. Real pul, to‘lov, pul yechish yoki mukofot sotib olish jarayoni yo‘q.
- **HR kvestlar:** EPAM, Uzum kabi nomlar bilan statik namunaviy topshiriqlar; ariza yuborish yoki ish beruvchi API integratsiyasi yo‘q.
- **EdTech vaucherlar:** Najot Ta’lim va Mohirdev nomlari bilan namunaviy kartalar; haqiqiy vaucher chiqarish yo‘q. Bu nomlar amaldagi hamkorlik isboti emas.
- **Karyera pasporti:** profil va statik soat/loyiha/reyting ko‘rsatkichlari.
- **GitHub/LeetCode:** namunaviy yozuvlar; real hisob ulash, commit yoki masala natijalarini olish yo‘q.
- **CV PDF:** tugma bor, `onPressed` bo‘sh; PDF yaratilmaydi.
- **Staking:** bosh sahifadagi 50 coin garov haqidagi matn statik; garov yechish/kuydirish mexanizmi topilmadi.
- `MockData.rewards` ichida 4 namunaviy mukofot mavjud, lekin yangi routerda katalog va redeem oqimi yo‘q.

## 5. Texnik holat va tekshiruv

- Platforma papkalari: Android, iOS va web. Bu barcha platformada muvaffaqiyatli build tasdiqlandi degani emas.
- Hozirgi paketlar: Flutter, Riverpod, GoRouter, SharedPreferences, Google Fonts, intl, equatable, UUID.
- Eski kod talab qiladigan, ammo `pubspec.yaml`da yo‘q paketlar: provider, firebase_core, firebase_auth, cloud_firestore, google_sign_in, flutter_local_notifications, flutter_timezone, timezone, mobile_scanner.
- `flutter analyze --no-pub`: **182 topilma — 145 error, 3 warning, 34 info**. Ularning katta qismi yo‘q importlarning davomiy xatolari; 145 ta mustaqil muammo degani emas.
- Faol kodning o‘zida ham `StateProvider` topilmaydi: `core/providers/app_providers.dart:19` va `:217`. Riverpod importini/API ishlatilishini moslashtirish zarur.
- `flutter test --no-pub`: **15 ta o‘tdi, 3 ta muvaffaqiyatsiz natija**. `app_state_restore_test.dart` va `notification_service_test.dart` dependencylar yo‘qligi sabab yuklanmadi. `local_storage_service_test.dart`dagi bitta test expected/actual farqi bilan yiqildi.
- Local storage testidagi farq: fixture ichida `profile` ham bor, ammo test saqlanib qolgan eski ma’lumotdan faqat `owner`ni kutadi. Bu natija o‘z-o‘zidan foydalanuvchi ma’lumoti yo‘qolganini ko‘rsatmaydi; testning kutilmasi bilan fixture mos emas.
- Testlar odat jadvali, recovery, boshlang‘ich fokuslar, local storage ajratilishi, legacy migratsiya, AppState restore va vaqt formatlarini qamrab olishga mo‘ljallangan.
- `widget_test.dart` faqat bo‘sh bo‘lmagan matnni tekshiradi. U butun ilova yoki ekranlar ishlashini tasdiqlamaydi.
- Yangi maqsad → diagnostika → roadmap → dars → natija oqimi uchun to‘liq test qamrovi topilmadi.
- README va oldingi audit hujjatlari joriy koddan orqada qolgan: yangi features qatlamini, faol Riverpod oqimini va hozirgi dependency holatini to‘liq aks ettirmaydi.

Loglar: `build/mpl_audit_analyze.log`, `build/mpl_audit_tests.log`.

## 6. Yangi oqimdagi aniq cheklov va nosozliklar

1. **Ishga tushirish:** faol provider faylida aniqlanmagan StateProvider bor. Butun repozitoriy ham analyze tekshiruvidan o‘tmaydi.
2. **AI:** diagnostika, reja va chatda haqiqiy AI yo‘q; generator shablonli.
3. **Baholash:** dars noto‘g‘ri javob uchun ham XP beradi; darsni qayta ochish orqali qayta mukofot olish cheklanmagan.
4. **Progress:** dars yakuni roadmap vazifasiga ulanmagan; umumiy roadmap foizi bajarilgan vazifalarga emas, tugallangan bosqichlar ulushiga qarab hisoblanadi.
5. **Bugun kartasi:** `_done` mahalliy holati keyingi vazifa kelganda qayta o‘rnatilmaydi. Birinchi vazifadan keyingi kartaning bajarish tugmasi nofaol qolishi mumkin. Bu koddan aniqlangan ehtimol, UI orqali qayta namoyish qilinmagan.
6. **XP tarixi:** `xpEventsProvider` SharedPreferencesni oddiy Provider orqali o‘qiydi. Yangi voqea yozilganda u invalidatsiya qilinmaydi; natijalar tarixi shu sessiyada eskicha qolishi mumkin.
7. **Tozalash:** `signOut` user/onboarded/goals/roadmaps kalitlarini o‘chiradi, lekin `mlp_xp_events`ni o‘chirmaydi. Goals, roadmaps va chat providerlarining xotiradagi holati ham reset qilinmaydi. Yangi profil oldingi tarix yoki rejalarni ko‘rishi mumkin.
8. **Ma’lumot ajralishi:** yangi `mlp_*` kalitlari eski `mylife_plan_app_data_v2_*` saqlashidan alohida. Eski odatlar va cloud hisobi yangi ekranlarga avtomatik ko‘chmaydi.
9. **Navigatsiya:** dars `context.go` bilan ochilib, chiqishda `context.pop` ishlatilgan. To‘g‘ridan-to‘g‘ri kirish va qaytish steki uchun tekshiruv/ishonchli qaytish yo‘li kerak.
10. **Maxfiylik matni:** onboardingda “Hech qanday haqiqiy ma’lumot saqlanmaydi” deyiladi, ammo ism/telefon/jins SharedPreferencesga yoziladi. Matn haqiqiy xatti-harakatga mos emas.
11. **Sozlamalar:** til, mavzu va bildirishnomalar hozir faqat ko‘rinish.

## 7. Amaliy xulosa va keyingi ishlar

Loyihaning mahsulot asosi keng: odatlar + o‘quv reja + rag‘batlantirish + karyera/market g‘oyalari. Joriy versiya yangi ta’lim interfeysiga o‘tish bosqichidagi demo prototip. To‘liq ishlaydigan AI ta’lim platformasi, mukofot bozori yoki HR integratsiyasi sifatida baholashga hali asos yo‘q.

Tavsiya etilgan tartib:

1. Faol ilovani kompilyatsiya qiladigan holatga keltirish; eski kodni saqlash yoki qayta ulash bo‘yicha aniq qaror.
2. Yagona router, provider va ma’lumot modeli; eski foydalanuvchi ma’lumotlarini ko‘chirish.
3. Profilni tozalash, XP takroriy berilishi, dars baholash, progress va qaytish navigatsiyasini tuzatish.
4. Asosiy foydalanuvchi oqimini qurilmada tekshirish va mazmunli test bilan yopish.
5. Shundan so‘ng haqiqiy autentifikatsiya/cloud, AI, dars kontenti va bildirishnomalarni ulash.
6. Real hamkorlik va server tasdig‘i mavjud bo‘lganda market, QR check-in, vaucher va HR oqimlarini ishga tushirish.

Tekshiruv davomida ilovaning funksional kodi o‘zgartirilmadi. Hisobot va diagnostika loglari qo‘shildi; avvaldan mavjud ishchi o‘zgarishlar saqlandi.
