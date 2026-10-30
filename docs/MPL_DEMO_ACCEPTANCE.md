# MPL demo: 10 ta qabul mezoni

Sana: 2026-10-19. Bu fayl **tekshiruv shartlari**, tayyor funksiyalar ro‘yxati emas. Kod bo‘yicha quyidagi boshlang‘ich holatlar mustaqil tekshiruvsiz bajarildi deb belgilanmaydi. Backend va haqiqiy uchinchi tomon sync ushbu demo chegarasidan keyin.

Har mezon faqat barcha tegishli bandlar dalil bilan tasdiqlanganda o‘tadi. Kod yozilishi, screenshot yoki testning nomi yakka holda funksiyaning ishlashini isbotlamaydi. Dalil qaydi shakli: **holat; commit/ishchi holat; tekshiruv buyrug‘i yoki UI qadami; sana; natija/log yoki screenshot manzili; qolgan cheklov**. Foiz kelishilgan demo doirasiga tegishli; investitsiya yoki bozor muvaffaqiyatiga emas.

## G1 — bozor va investorga halol taqdimot

Boshlang‘ich holat: **hujjatlar tayyor, mazmun tekshirildi; foydalanuvchi/pilot dalillari kutilmoqda**.

- Raqiblar rasmiy manbalar bilan, tekshiruv sanasi ko‘rsatilgan holda solishtirilgan; Balance screenshot manbasi va LifeOS vizual reference chegarasi qayd etilgan.
- Talabalar/yosh mutaxassislar auditoriyasi, dastlabki pilot gipotezasi va kundalik foyda sikli aniq.
- 22/100 boshlang‘ich baho mezonli va subyektiv deb belgilangan; demo bitishi uni avtomatik 100/100 qilmaydi.
- Investor konsepti muammo, taklif, model, kanal, 90 kunlik tekshiruv va pilot so‘rovini qamrab olgan; traction, hamkorlik va investitsiya kafolati uydirilmagan.
- Manba: `docs/MPL_MARKET_STRATEGY_UZ.md` va `docs/MPL_INVESTOR_BRIEF_UZ.md`. Haqiqiy intervyu/retention/to‘lov mazkur hujjatlar mavjudligi bilan tasdiqlanmaydi.

## G2 — foydali mahalliy kundalik oqim

Boshlang‘ich holat: **kutilmoqda — ishlaydigan ilovada tekshiriladi**.

- O‘rnatilgan yoki oldindan yuklangan ilovada internet o‘chirilganda maqsad → bugungi vazifa → fokus → natija qaydi → haftalik ko‘rib chiqish bajariladi.
- Majburiy telefon, cloud hisob yoki API kalitisiz birinchi foydali ishga kirish mumkin.
- Ilova yopilib qayta ochilganda yozilgan foydalanuvchi ma’lumoti saqlanadi; yangi sessiya ishni davom ettiradi.
- Demo yozuvlari bo‘lsa namunaviyligi tushunarli; foydalanuvchi o‘z ma’lumotini kiritib haqiqiy kundalik ish yurita oladi. Bo‘sh holatda foydali keyingi harakat bor.
- “Bugun” sanasi foydalanuvchi mahalliy sanasiga mos; kun almashtirishda yangi kun vazifalari ishlaydi.

## G3 — vazifa va natija topshirish

Boshlang‘ich holat: **kutilmoqda — kod va UI dalili kerak**.

- Vazifa yaratish, tahrirlash, sanasi/ustuvorligi/rejalangan vaqtini belgilash va o‘chirish amalda ishlaydi.
- Vazifaga natija matni va ixtiyoriy havola yoziladi, saqlanadi va qayta ochilganda ko‘rinadi. Noto‘g‘ri yoki bo‘sh kirish tushunarli tekshiriladi.
- Natija manbasi “foydalanuvchi qaydi” sifatida tushunarli; server yoki mentor tasdig‘i bo‘lmasa “tasdiqlangan” deyilmaydi.
- Bajarish/bekor qilish progressni yangilaydi. Bir xil vazifa/kunni qayta bosish yoki qayta ochish XP/natijani takror oshirmaydi.
- Rejalashtirilgan vaqt kundalik sig‘imga solishtiriladi; ortiqcha yuk va keyinga ko‘chirish foydalanuvchiga ko‘rinadi.

## G4 — odatlar va jadval

Boshlang‘ich holat: **kutilmoqda — jadval va qayta ochish tekshiriladi**.

- Odat yaratish/tahrirlash/o‘chirish, kunlik yoki tanlangan hafta kunlari jadvali bor.
- Tanlangan sanada faqat tegishli odatlar kutiladi; ishlanmaydigan kun bajarilmagan deb xato hisoblanmaydi.
- Check-in va undo bitta sana/odat doirasida ishlaydi; qayta ochishda saqlanadi. Sonli maqsad taklif etilsa qiymat va birlik haqiqiy logga bog‘langan.
- Odatning miqdori/birligi/jadvali tahrirlansa avval yozilgan kunlar o‘z thresholdi va birligini saqlaydi; yangi qoida hali qayd kiritilmagan kunlarda ishlaydi.
- Streak, bajarilgan kun va heatmap mavjud bo‘lsa kelajak kunlari yoki rejasiz kunlar uni sun’iy oshirmaydi/buzmaydi.
- Bir kun o‘tkazib yuborilganda qaytish uchun kichik ish yoki qayta rejalash mumkin; demo muqarrar muvaffaqiyat va’dasini bermaydi.

## G5 — maqsad va haqiqiy progress

Boshlang‘ich holat: **kutilmoqda — model va ekranda tekshiriladi**.

- Foydalanuvchi nom, o‘lchanadigan natija, muddat/vaqt sig‘imi bilan maqsad yarata oladi va tahrirlaydi.
- Vazifa maqsadga bog‘lanadi; qo‘shish, bajarish, undo va o‘chirish bog‘langan jami/bajarilgan vazifalar hisobini to‘g‘ri o‘zgartiradi. Maqsadning `current` soni foydalanuvchi qo‘lda kiritadigan mutlaq o‘lchov bo‘lib qoladi: vazifa tugashi avtomatik ravishda kitob, dars yoki boshqa birlik yaratmaydi.
- Foiz nimani o‘lchashi aniq: vazifalar bajarilishi maqsadning tashqi hayotdagi kafolatlangan natijasi sifatida ko‘rsatilmaydi.
- Tayyor reja/shablon foydalanuvchi tanloviga mos boshlang‘ich ish beradi va o‘zgartiriladi; shablon generator haqiqiy AI deb nomlanmaydi.
- Maqsadlar ro‘yxati va maqsadsiz bo‘sh holatda ham navigatsiya ishlaydi.

## G6 — real vaqtga bog‘langan fokus

Boshlang‘ich holat: **kutilmoqda — jonli taymer tekshiruvi kerak**.

- Fokus aniq vazifa/maqsadga bog‘lanadi; davomiylik tanlash, boshlash, pauza, davom ettirish va bekor qilish ishlaydi.
- O‘tgan vaqt devordagi soatga mos; 25 daqiqalik sessiya bir necha soniyada haqiqiy bajarilgan deb yozilmaydi.
- Brauzer tabini almashtirish yoki render to‘xtashidan so‘ng timer drift hisobiga noto‘g‘ri vaqt qo‘shmaydi; pauzadagi vaqt fokusga kirmaydi.
- Tugallangan yoki foydalanuvchi saqlagan sessiya faqat bir marta yoziladi; bekor qilingan vaqtning saqlanish siyosati aniq.
- Qayta yuklash/yopish holati sinovdan o‘tadi: sessiya to‘g‘ri tiklanadi yoki tushunarli yakun holatiga o‘tadi. Ilovalar bloklandi degan da’vo real OS imkoniyatisiz qo‘yilmaydi.

## G7 — hisoblangan natijalar va haftalik review

Boshlang‘ich holat: **kutilmoqda — hisoblashlar va UI tekshiriladi**.

- Bugungi/haftalik vazifa, odat, fokus va natija ko‘rsatkichlari saqlangan yozuvlardan hisoblanadi.
- Test ma’lumotidagi kutilgan sonlar ekrandagi qiymatga mos; yozuv qo‘shish/undo/o‘chirish shu sessiyada ko‘rinadi.
- Namuna raqami yoki o‘lchovsiz “Flow State”, HRV, uyqu, diqqat foizi foydalanuvchining real tahlili deb ko‘rsatilmaydi.
- Haftalik reviewda nima ishlagani, to‘siq va keyingi qadamni yozish/saqlash mumkin; keyingi reja shu ma’lumotga tayanib foydalanuvchi tomonidan o‘zgartiriladi.
- Xulosa qoidaga asoslangan bo‘lsa tushunarli; “AI tahlil” yoki sabab-oqibat da’vosi dalilsiz berilmaydi.

## G8 — rost nomlangan qo‘lda integratsiya

Boshlang‘ich holat: **kutilmoqda — eksport/import amalda tekshiriladi**.

- JSON backup eksporti va importi amalda ishlaydi; import oldidan format/schema tekshiriladi, noto‘g‘ri fayl mavjud ma’lumotni buzmaydi.
- Vazifa/natijani matn yoki havola shaklida nusxalash/ulashish mumkin. Foydalanuvchi harakatini talab qiluvchi oqim avtomatik yuborish deb ko‘rsatilmaydi.
- Kalendar uchun ICS/event havolasi taklif qilinsa sana, davomiylik va vaqt mintaqasi to‘g‘ri; qayta import/sync haqidagi chegarasi aniq.
- CSV import taklif qilinsa qo‘llab-quvvatlangan ustunlar, xatolar va takror yozuv siyosati ko‘rsatilgan; taklif qilinmagan format ishlaydi deb ko‘rsatilmaydi.
- Hisob ulanmagan bo‘lsa Google, Todoist, Notion, Telegram yoki boshqa xizmat yonida “ulangan/sinxronlash faol” belgisi yo‘q. Keyingi OAuth/API ishlari alohida reja sifatida turadi.

## G9 — mahalliy ma’lumot ishonchliligi

Boshlang‘ich holat: **kutilmoqda — buzilish, import va reset tekshiriladi**.

- Demo qanday ma’lumotni qayerda saqlashi tushunarli; ism/yozuv saqlansa “hech narsa saqlanmaydi” deyilmaydi.
- Mavjud eski ma’lumot ruxsatsiz almashtirilmaydi/o‘chirilmaydi; yangi demo kalitlari yoki migratsiya qoidasi aniq.
- Backup → o‘zgartirish → import qilishda vazifa, odat, maqsad, natija va fokus yaxlitligi tekshiriladi; takror yozuv boshqariladi.
- Buzilgan/eskirgan ma’lumotdan yuklashda app qulamaydi va tiklash yo‘li bor; yozish muvaffaqiyatsizligi yashirin muvaffaqiyat deb ko‘rsatilmaydi.
- “Ma’lumotlarni tozalash” tasdiqlanganidan so‘ng appga tegishli vazifa, odat, maqsad, natija, sessiya/taymer va tarix xotiradan ham saqlashdan ham yo‘qoladi; qayta ochishda eski yozuv qaytmaydi.
- Secret/API/bot tokenlar front-end ichida yo‘q; foydalanuvchi natijalari o‘zidan o‘zi tashqi xizmatga yuborilmaydi.

## G10 — tekshiruv, responsive runtime va topshirish

Boshlang‘ich holat: **kutilmoqda — yakuniy ishchi holat bo‘yicha dalil kerak**.

- `flutter analyze` xatosiz; qolgan ogohlantirishlar bo‘lsa mazmuni va demo ta’siri ochiq qayd etilgan.
- Tegishli `flutter test`lar o‘tadi: jadval, sanaga bog‘langan check-in/undo, takror mukofot, fokus vaqti, progress, saqlash/import/reset kabi mahsulot invariantlari tekshirilgan. Faqat widget mavjudligi testi yetarli emas.
- Kamida demo mo‘ljallangan platforma uchun build muvaffaqiyatli. Web demo uchun `flutter build web` va shu build bilan ishlaydigan sahifa tekshiriladi.
- 390×844 va 1440×900 ko‘rinishlarda asosiy kundalik oqim, modal/formalar, navigatsiya va matn maydonlari ishlaydi; overflow yoki yashirin asosiy harakat yo‘q. Klaviatura va bo‘sh/xato holatlar ham tekshiriladi.
- Jonli taymer, tabni almashtirish, qayta yuklash, offline ishlash va eksport/import qo‘lda kuzatilgan; screenshot/log joylari yozilgan. Repozitoriy testi jonli UI dalili o‘rniga berilmaydi.
- Qisqa ishga tushirish yo‘li, qo‘llab-quvvatlangan platforma va qolgan backend ishlari yetkazilgan. Yakuniy demo bahosi boshlang‘ich 22/100 bozor/mahsulot rubrikasidan ajratilgan.
- Investorga 90 soniyalik ko‘rsatish ssenariysi G2–G8dagi haqiqiy ishlardan tuziladi; investor konsepti va 90 kunlik pilot rejasi mavjud, ko‘rsatilayotgan namuna ma’lumot haqiqiy traction deyilmaydi.

## Yakuniy qaror qoidasi

**Demo qabul qilindi** faqat G1–G10ning tegishli demo bandlari dalil bilan yopilganda yoziladi. Haqiqiy bozor validatsiyasi, cloud sync, real AI, pul/mukofot va imzolangan hamkorlikning mavjud emasligi ochiq qoladi. Pilot natijalari keyingi biznes qarorining dalili; ular demo ichida uydirilmaydi.
