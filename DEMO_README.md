# MPL (MYLife Plan) Demo — Ishga Tushirish va Qo'llanma

Bu loyiha **MYLife Plan (MPL) Demo** prototipi bo'lib, talabalar va junior mutaxassislar uchun shaxsiy rivojlanish, vazifalar, fokus taymeri va natijalar portfelini yagona tizimda jamlaydi.

> **Eslatma:** Ushbu versiya 100% lokal (`SharedPreferences`) asosida ishlaydi. Hech qanday tashqi backend, Firebase yoki pullik AI API talab qilinmaydi.

---

## 🚀 1. Ishga tushirish (Run)

### A) Web orqali (Tavsiya etiladi - Tez va qulay)

Tayyor reliz artefakti `build/web/` katalogida mavjud. Uni quyidagi buyruq bilan lokal serverda ochishingiz mumkin:

```bash
# Terminalda (loyiha papkasida):
flutter run -d chrome
```

Yoki mavjud reliz buildni server orqali ko'rish:
```bash
# Agar Python o'rnatilgan bo'lsa:
python -m http.server 8080 --directory build/web
# Brauzerda oching: http://localhost:8080
```

*(Eslatma: `build/web/index.html` faylini to'g'ridan-to'g'ri `file://` orqali ochmang, veb brauzerlar xavfsizlik cheklovlari tufayli lokal HTTP server talab qiladi).*

### B) Android Telefonda (USB orqali)

Agar telefoningiz ulangan bo'lsa:
```bash
flutter run
```

---

## 📱 2. Demo Imkoniyatlari (90 soniyalik ssenariy)

1. **Bugun (Today)**: 
   - Kunlik rejalashtirilgan ishlar va umumiy vaqt sig'imi (masalan, 180 daqiqa).
   - Vazifalar ustuvorligi va loyihalar bo'yicha ajratilishi.
2. **Vazifa & Natija (Proof of Work)**:
   - Vazifani bajarishda kamida 10 belgilik natija izohi va ixtiyoriy havola kiritiladi (self-report).
   - Bir xil vazifaga qayta-qayta XP yozilmaydi.
3. **Fokus Taymeri (Live Focus)**:
   - Pomodoro (25/50 daqiqa) yoki 1 daqiqalik test fokus.
   - Faqat haqiqiy o'tgan aktiv vaqt hisoblanadi va saqlanadi.
4. **Odatlar (Habits)**:
   - Kunlik yoki tanlangan hafta kunlari bo'yicha jadval.
   - Miqdor kiritish (+1) va xato bosilganda `undo` imkoniyati.
5. **Natijalar & Eksport**:
   - 7 kunlik statistika va topshirilgan ishlar portfeli.
   - JSON formatida zaxira nusxa (backup) olish va qayta tiklash (import).

---

## 🧪 3. Testlar va Kod Sifati

Barcha testlar to'liq avtomatlashtirilgan:
```bash
flutter test --no-pub
```
- **59/59 testlar** muvaffaqiyatli o'tgan (100% pass).
- Analizator: **0 xato, 0 ogohlantirish, 0 lint info**.
