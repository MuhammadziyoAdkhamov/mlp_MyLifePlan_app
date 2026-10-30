import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../app/mlp_environment.dart';
import 'mlp_companion_pages.dart';

/// Reads the Gemini API key injected at compile time via --dart-define.
/// Run: flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
const String _kApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// System instruction that gives the AI full context about MLP app and
/// teaches it to reply in Uzbek, in a helpful life-coach style.
const String _kSystemInstruction = '''
Sen MYLife Plan (MLP) ilovasining shaxsiy rivojlanish va hayot murabbiy (life coach) yordamchisisisan.
Foydalanuvchi maqsadlarini bajarishda, odatlarni rivojlantirishda va vaqtni boshqarishda yordam berasan.
Har doim o'zbek tilida, qisqa, ilhomlantiruvchi va amaliy maslahatlarsiz javob berasan.
Javoblar 3-5 jumladan oshmasin. Agar foydalanuvchi ma'lumot berishni so'rasa, aniq va sodda tushuntir.
Agar savolda muayyan vazifa yoki maqsad bo'lsa, birinchi navbatda shu kontekstga asoslangin.
''';

class MLPGeminiAdapter implements MLPAssistantAdapter {
  MLPGeminiAdapter({String? apiKey}) : _apiKey = apiKey ?? _kApiKey;

  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _session;

  bool get isConfigured => _apiKey.isNotEmpty;

  void _init(String systemContext) {
    if (_model != null) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.75,
        topP: 0.95,
        maxOutputTokens: 512,
      ),
      systemInstruction: Content.system(
        '$_kSystemInstruction\n\nFoydalanuvchi konteksti:\n$systemContext',
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
    return [
      'Bugungi vazifalar: $done/$total bajarildi.',
      'Fokus vaqti: $focus daqiqa.',
      if (next != null) 'Keyingi vazifa: ${next.title} (${next.minutes} daqiqa).',
    ].join(' ');
  }

  @override
  Future<String> reply(String question, MLPEnvironment e) async {
    if (!isConfigured) {
      return 'Gemini API kaliti topilmadi. Ilovani '
          '--dart-define=GEMINI_API_KEY=... bilan ishga tushiring.';
    }
    _init(_buildContext(e));
    try {
      final tone = e.ui.preferences.tone;
      final prompt = tone == 'Batafsil'
          ? '$question\n(Batafsil izoh ber)'
          : tone == 'Qo\'llab-quvvatlovchi'
          ? '$question\n(Mehribon va rag\'batlantiruvchi ohangda javob ber)'
          : question;

      final response = await _session!.sendMessage(Content.text(prompt));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return 'Javob bo\'sh keldi. Qayta urinib ko\'ring.';
      }
      return text;
    } on GenerativeAIException catch (e) {
      return 'Gemini xatosi: ${e.message}. Keyinroq urinib ko\'ring.';
    } catch (e) {
      return 'Tarmoq xatosi yuz berdi. Internetni tekshiring va qayta urinib ko\'ring.';
    }
  }

  /// Reset chat history (new conversation)
  void reset() {
    _session = null;
    _model = null;
  }
}
