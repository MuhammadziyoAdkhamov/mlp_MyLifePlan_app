import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../app/mlp_environment.dart';
import 'mlp_companion_pages.dart';

/// Reads the Gemini API key injected at compile time via --dart-define.
/// Run: flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
const String _kDefaultApiKey = String.fromEnvironment('GEMINI_API_KEY');

const String _kSystemInstruction = '''
Sen MYLife Plan (MLP) ilovasining shaxsiy rivojlanish va hayot murabbiyi (life coach) "Ziyo"san.
Foydalanuvchiga maqsadlarini rejalashtirishda, odatlarni shakllantirishda, vaqtni boshqarishda va intizomni kuchaytirishda do'stona, ilhomlantiruvchi va amaliy tavsiyalar berasan.
Talablar:
1. Har doim toza o'zbek tilida (lotin alifbosida), samimiy va professional javob ber.
2. Javoblaring aniq, amaliy va rag'batlantiruvchi bo'lsin. 3-5 ta lo'nda jumlada asosiy mohiyatni tushuntir.
3. Agar foydalanuvchining bugungi vazifalari yoki fokusi haqida ma'lumot berilgan bo'lsa, javobingda shu kontekstga tayangan holda maslahat ber.
4. Hech qachon shaxsiy ma'lumotlarni so'rama yoki keraksiz rasmiyatchilik qilma.
''';

class MLPGeminiAdapter implements MLPAssistantAdapter {
  MLPGeminiAdapter({String? apiKey}) : _fallbackKey = apiKey ?? _kDefaultApiKey;

  final String _fallbackKey;
  String? _activeKey;
  GenerativeModel? _model;
  ChatSession? _session;

  String resolveApiKey(MLPEnvironment e) {
    final storedKey = e.prefs.getString('mlp_gemini_api_key')?.trim() ?? '';
    if (storedKey.isNotEmpty) return storedKey;
    if (_fallbackKey.isNotEmpty) return _fallbackKey;
    return _kDefaultApiKey;
  }

  bool hasKey(MLPEnvironment e) => resolveApiKey(e).isNotEmpty;

  void _initIfNeeded(String apiKey, String systemContext) {
    if (_model != null && _activeKey == apiKey) return;
    _activeKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.75,
        topP: 0.95,
        maxOutputTokens: 600,
      ),
      systemInstruction: Content.system(
        '$_kSystemInstruction\n\nFoydalanuvchi ma\'lumotlari:\n$systemContext',
      ),
    );
    _session = _model!.startChat();
  }

  String _buildContext(MLPEnvironment e) {
    if (!e.ui.preferences.allowContext) return 'Kontekst o\'chirilgan.';
    final tasks = e.store.todayTasks;
    final done = tasks.where((t) => t.completed).length;
    final total = tasks.length;
    final focus = e.store.todayFocusMinutes;
    final next = tasks.where((t) => !t.completed).firstOrNull;
    final name = e.ui.profile?.name ?? 'Foydalanuvchi';
    final goals = e.store.goals.take(3).map((g) => g.title).join(', ');
    return [
      'Ism: $name.',
      'Bugungi vazifalar: $done/$total bajarildi.',
      'Fokus vaqti: $focus daqiqa.',
      if (next != null) 'Keyingi vazifa: "${next.title}" (${next.minutes} daqiqa).',
      if (goals.isNotEmpty) 'Asosiy maqsadlar: $goals.',
      'Uslub: ${e.ui.preferences.tone}.',
    ].join(' ');
  }

  @override
  Future<String> reply(String question, MLPEnvironment e) async {
    final apiKey = resolveApiKey(e);
    final contextText = _buildContext(e);

    if (apiKey.isEmpty) {
      // Smart offline life coach in Uzbek
      return _generateOfflineLifeCoachReply(question, e);
    }

    _initIfNeeded(apiKey, contextText);

    try {
      final tone = e.ui.preferences.tone;
      final prompt = tone == 'Batafsil'
          ? '$question\n(Iltimos, bosqichma-bosqich va batafsil tushuntirib bering)'
          : tone == 'Qo\'llab-quvvatlovchi'
              ? '$question\n(Iltimos, iliq, do\'stona va ruhiy dalda beruvchi ohangda javob bering)'
              : question;

      final response = await _session!.sendMessage(Content.text(prompt));
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return _generateOfflineLifeCoachReply(question, e);
    } on GenerativeAIException catch (err) {
      final fallback = _generateOfflineLifeCoachReply(question, e);
      return '$fallback\n\n*(Gemini API xabari: ${err.message})*';
    } catch (_) {
      final fallback = _generateOfflineLifeCoachReply(question, e);
      return '$fallback\n\n*(Tarmoq uzilishi: javob offline rejimda shakllantirildi)*';
    }
  }

  /// Verifies connection with the given API key.
  static Future<bool> testConnection(String apiKey) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(maxOutputTokens: 20),
      );
      final res = await model.generateContent([Content.text('Salom')]);
      return res.text != null && res.text!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _generateOfflineLifeCoachReply(String question, MLPEnvironment e) {
    final q = question.toLowerCase();
    final task = e.store.todayTasks.where((t) => !t.completed).firstOrNull;
    final name = e.ui.profile?.name ?? 'do‘stim';

    if (q.contains('salom') || q.contains('assalomu')) {
      return 'Assalomu alaykum, $name! Bugungi rejalaringizni amalga oshirishda sizga yordam berishdan xursandman. Nimadan boshlaymiz?';
    }
    if (q.contains('motivatsiya') || q.contains('ruh')) {
      return 'Katta marralar har kuni qilinadigan kichik, barqaror qadamlardan boshlanadi. Bugun bor e’tiboringizni bitta asosiy vazifaga qarating — natija sizni hayratda qoldiradi!';
    }
    if (q.contains('reja') || q.contains('bugun')) {
      final completed = e.store.todayTasks.where((t) => t.completed).length;
      final total = e.store.todayTasks.length;
      if (task != null) {
        return 'Bugun $total ta vazifadan $completed tasi bajarildi. Hozir eng yaxshi qadam — «${task.title}» vazifasiga 25 daqiqa chuqur fokus qilishdir!';
      }
      return 'Bugun barcha asosiy vazifalaringiz muvaffaqiyatli yakunlangan yoki hali reja kiritilmagan. Keling, ertangi kun uchun yangi maqsadlar belgilaymiz!';
    }
    if (q.contains('flutter') || q.contains('kod') || q.contains('dasturlash')) {
      return 'Flutter dasturlashda eng muhim qoida — kodni kichik, qayta ishlatiladigan vidjetlarga ajratish va state (holat) boshqaruvini to‘g‘ri tanlashdir. Biror vidjet yoki mavzuda yordam kerakmi?';
    }
    if (q.contains('vaqt') || q.contains('ulgurmayapman') || q.contains('charchadim')) {
      return 'Vaqt yetishmasligining eng yaxshi yechimi — vazifalarni «Pomodoro» (25 daqiqa fokus + 5 daqiqa tanaffus) usulida bo‘lib chiqishdir. Boshlanishiga faqat 5 daqiqa ajrating.';
    }

    return 'Ajoyib savol! Maqsad sari intilishda eng asosiysi — muntazamlik. Hozirgi harakatingiz sizni ko‘zlagan natijaga bir qadam yaqinlashtiradi.';
  }

  void reset() {
    _session = null;
    _model = null;
    _activeKey = null;
  }
}
