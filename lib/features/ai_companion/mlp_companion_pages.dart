import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import 'mlp_ai_orb.dart';

abstract interface class MLPAssistantAdapter {
  Future<String> reply(String question, MLPEnvironment e);
}

class MLPDemoAssistant implements MLPAssistantAdapter {
  const MLPDemoAssistant();
  @override
  Future<String> reply(String question, MLPEnvironment e) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final answer = response(question, e);
    return switch (e.ui.preferences.tone) {
      'Qo‘llab-quvvatlovchi' =>
        'Shoshilmang, bitta kichik qadam ham yetarli.\n\n$answer',
      'Batafsil' =>
        '$answer\n\n1. Natijani aniq yozing.\n2. Vaqtni taqvimda belgilang.\n3. Fokusdan keyin nima qilganingizni qayd eting.\nBu faqat demo tavsiya, rejangiz o‘zgartirilmadi.',
      _ => answer,
    };
  }

  String response(String question, MLPEnvironment e) {
    final q = question.toLowerCase();
    final context = e.ui.preferences.allowContext;
    final task = e.store.todayTasks.where((t) => !t.completed).firstOrNull;
    if (q.contains('flutter')) {
      return 'Demo tushuntirish: Flutter interfeysi widgetlardan tuziladi. Avval bitta kichik ekran yarating, so‘ng forma validatsiyasi va mahalliy saqlovni tekshiring. Bu tayyor namuna javobi, jonli model emas.';
    }
    if (q.contains('oson') || q.contains('ortda')) {
      return context && task != null
          ? 'Demo taklif: «${task.title}» ishining faqat birinchi 5 daqiqalik qadamini bajaring. ${task.minutes} daqiqalik taxminni kerak bo‘lsa tahrirlang. Tezlik ko‘nikma darajasini isbotlamaydi.'
          : 'Demo taklif: bir vazifani tanlab, 5 daqiqalik eng kichik qadamdan boshlang. Qolgan ishni keyingi vaqtga rejalang.';
    }
    if (q.contains('ertangi')) {
      return 'Demo taklif: ertangi kun uchun bitta muhim natija va aniq vaqt ajrating. Taqvimdagi to‘qnashuv va kunlik sig‘imni tekshiring. Jadval avtomatik o‘zgartirilmadi.';
    }
    return context
        ? 'Demo tahlil: bugungi ${e.store.todayTasks.length} vazifadan ${e.store.todayTasks.where((t) => t.completed).length} tasi topshirilgan; ${e.store.todayFocusMinutes} daqiqa fokus saqlangan. ${task == null ? 'Yangi maqsad yoki kichik qayd tanlang.' : 'Keyingi qadam: ${task.title}.'} Bu mahalliy holatga asoslangan belgilangan javob.'
        : 'Demo yordamchi: bugungi bitta muhim vazifadan boshlang. Maqsad va vazifalar konteksti o‘chirilgan. Uni «Ustozni moslash» bo‘limida ixtiyoriy yoqishingiz mumkin.';
  }
}

class MLPChatPage extends StatefulWidget {
  const MLPChatPage({
    super.key,
    required this.e,
    this.adapter = const MLPDemoAssistant(),
    this.showBack = false,
  });
  final MLPEnvironment e;
  final MLPAssistantAdapter adapter;
  final bool showBack;
  @override
  State<MLPChatPage> createState() => _ChatState();
}

class _ChatState extends State<MLPChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  String? error, pending;

  static const suggestions = [
    (
      Icons.favorite_border_rounded,
      'Meni motivatsiya qil',
      'Vazifamni osonlashtir.',
    ),
    (
      Icons.assignment_outlined,
      'Bugungi rejamni tuzib ber',
      'Bugungi rejamni tahlil qil.',
    ),
    (Icons.schedule_rounded, 'Vaqtimni boshqarish', 'Nega ortda qolyapman?'),
    (
      Icons.route_rounded,
      'Ertangi kunni rejalash',
      'Ertangi kunimni rejalashtir.',
    ),
    (
      Icons.code_rounded,
      'Flutter haqida savol',
      'Flutter mavzusini tushuntir.',
    ),
  ];

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? suggestion]) async {
    if (busy) return;
    final question = (suggestion ?? input.text).trim();
    if (question.isEmpty || question.length > 1000) {
      setState(() => error = 'Savol 1–1000 belgi bo‘lsin.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
      pending = question;
    });
    try {
      final answer = await widget.adapter.reply(question, widget.e);
      await widget.e.ui.saveConversationTurn(
        question,
        answer,
        widget.e.clock(),
      );
      if (!mounted) return;
      input.clear();
      setState(() {
        busy = false;
        pending = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          final duration = MLPDimensions.motion(context);
          if (duration == Duration.zero) {
            scroll.jumpTo(scroll.position.maxScrollExtent);
          } else {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: duration,
              curve: Curves.easeOutCubic,
            );
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Javob olishda xato yuz berdi. Qayta urinib ko‘ring.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.e.ui,
    builder: (context, _) {
      final e = widget.e, messages = widget.e.ui.messages;
      final userName = e.ui.profile?.name.trim();
      final greetingName = userName == null || userName.isEmpty
          ? 'do‘stim'
          : userName;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 10, 4),
            child: Row(
              children: [
                if (widget.showBack)
                  const BackButton()
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: MLPColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ustoz AI',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Shaxsiy rivojlanish yordamchingiz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ustozni moslash',
                  onPressed: () => e.go(MLPScreen.aiPersonalization),
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: messages.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    children: [
                      if (messages.isEmpty) ...[
                        MLPAINebula(
                          active: busy,
                          height: MediaQuery.sizeOf(context).height < 600
                              ? 150
                              : 195,
                        ),
                        MLPLiquidSurface(
                          radius: 19,
                          tint: const Color(0xFF13244B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Salom, $greetingName! 👋',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Bugun qanday yordam bera olaman?\nMaqsadlaringiz sari birgalikda\nharakat qilamiz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: MLPColors.secondaryText,
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _suggestionRow(suggestions.take(2).toList()),
                        const SizedBox(height: 7),
                        _suggestionRow(suggestions.skip(2).toList()),
                        const SizedBox(height: 14),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: MLPColors.primary,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${e.ui.preferences.nickname} bilan suhbat',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MLPColors.secondaryText,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => e.go(MLPScreen.voice),
                              icon: const Icon(
                                Icons.mic_none_rounded,
                                size: 17,
                              ),
                              label: const Text('Ovoz'),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Oxirgi 100 xabar shu qurilmada saqlanadi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MLPColors.muted,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                if (i == messages.length + 1) {
                  return Column(
                    children: [
                      if (busy)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MLPColors.turquoise,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ustoz AI javob yozmoqda…',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (error != null)
                        MLPErrorState(
                          message: error!,
                          onRetry: () => send(pending),
                        ),
                    ],
                  );
                }
                final message = messages[i - 1],
                    mine = message['role'] == 'user';
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 12,
                      left: mine ? 28 : 0,
                      right: mine ? 0 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: MLPLiquidSurface(
                        blur: false,
                        radius: 18,
                        tint: mine
                            ? const Color(0xFF14354A)
                            : const Color(0xFF1B203C),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mine ? 'Siz' : e.ui.preferences.nickname,
                              style: TextStyle(
                                color: mine
                                    ? MLPColors.turquoise
                                    : MLPColors.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              '${message['text']}',
                              style: const TextStyle(height: 1.6, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: MLPLiquidSurface(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Ovozli suhbat ko‘rinishi',
                      onPressed: busy ? null : () => e.go(MLPScreen.voice),
                      icon: const Icon(
                        Icons.mic_none_rounded,
                        size: 20,
                        color: MLPColors.secondaryText,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: input,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 1000,
                        enabled: !busy,
                        textInputAction: TextInputAction.send,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(fontSize: 13, height: 1.5),
                        decoration: const InputDecoration(
                          hintText: 'Savolingizni yozing…',
                          hintStyle: TextStyle(
                            color: MLPColors.muted,
                            fontSize: 12,
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 0,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    MLPCircleAction(
                      label: 'Xabarni yuborish',
                      size: 40,
                      icon: busy
                          ? Icons.hourglass_top_rounded
                          : Icons.near_me_rounded,
                      onPressed: busy ? null : () => send(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _suggestionRow(List<(IconData, String, String)> items) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: MLPPressResponse(
                    child: ActionChip(
                      avatar: Icon(
                        entry.$1,
                        size: 14,
                        color: MLPColors.primaryLight,
                      ),
                      label: Text(
                        entry.$2,
                        style: const TextStyle(fontSize: 10),
                      ),
                      labelPadding: const EdgeInsets.only(left: 2, right: 3),
                      backgroundColor: MLPColors.primary.withValues(alpha: .08),
                      side: BorderSide(
                        color: MLPColors.primary.withValues(alpha: .35),
                        width: .7,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : () => send(entry.$3),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class MLPVoicePage extends StatefulWidget {
  const MLPVoicePage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPVoicePage> createState() => _VoiceState();
}

class _VoiceState extends State<MLPVoicePage> {
  MLPOrbState state = MLPOrbState.idle;
  static const modes = [
    MLPOrbState.listening,
    MLPOrbState.thinking,
    MLPOrbState.speaking,
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.e.ui,
    builder: (context, _) {
      final e = widget.e, muted = widget.e.ui.preferences.muted;
      final status = muted
          ? 'Demo ovoz holati o‘chirilgan'
          : switch (state) {
              MLPOrbState.listening => 'Eshitmoqda...',
              MLPOrbState.thinking => 'O‘ylash animatsiyasi',
              MLPOrbState.speaking => 'Javob yozmoqda...',
              _ => 'Suhbatga tayyorman',
            };
      return MLPPage(
        title: 'Ovozli suhbat',
        actions: [
          IconButton(
            tooltip: 'Ustozni moslash',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => e.go(MLPScreen.aiPersonalization),
          ),
        ],
        children: [
          Text(
            'Ustoz AI',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            e.ui.preferences.nickname,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MLPColors.secondaryText),
          ),
          MLPAINebula(
            height: MediaQuery.sizeOf(context).height < 600 ? 175 : 255,
            active: state != MLPOrbState.idle,
            muted: muted,
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MLPColors.turquoise,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const MLPNotice(
            'Ovozli suhbat tez orada. Hozircha matn orqali suhbatlashing.',
          ),
          MLPLiquidSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Ovoz holatlarini ko‘rish',
                  style: TextStyle(
                    fontSize: 12,
                    color: MLPColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                MLPSegmented(
                  labels: const ['Tinglash', 'O‘ylash', 'Javob'],
                  selected: muted || state == MLPOrbState.idle
                      ? -1
                      : modes.indexOf(state),
                  onChanged: (i) {
                    if (!muted) setState(() => state = modes[i]);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        muted
                            ? 'Ovoz holatini yoqish'
                            : 'Demo ovoz holatini o‘chirish',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Semantics(
                      label: 'Ovoz holati',
                      child: CupertinoSwitch(
                        value: !muted,
                        activeTrackColor: MLPColors.turquoise,
                        onChanged: (_) => e.act(
                          context,
                          () => e.ui.savePreferences(
                            MLPUserPreferences.fromJson({
                              ...e.ui.preferences.toJson(),
                              'muted': !muted,
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: MLPCircleAction(
              label: 'Suhbatni tugatish va chatga qaytish',
              icon: Icons.call_end_rounded,
              color: const Color(0xFFFF7B91),
              size: 64,
              onPressed: () {
                setState(() => state = MLPOrbState.idle);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  e.go(MLPScreen.chat);
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chatga qaytish',
            textAlign: TextAlign.center,
            style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 28),
          const MLPSectionHeader(
            title: 'Chat matnlari · audio transkript emas',
          ),
          const SizedBox(height: 12),
          if (e.ui.messages.isEmpty)
            const MLPEmptyState(
              title: 'Suhbat hali yo‘q',
              message: 'Chatdagi saqlangan xabarlar shu yerda ko‘rinadi.',
            ),
          ...e.ui.messages.reversed
              .take(6)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MLPLiquidSurface(
                    blur: false,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${m['role'] == 'user' ? 'Siz' : e.ui.preferences.nickname}: ${m['text']}',
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class MLPAIPreferencesPage extends StatefulWidget {
  const MLPAIPreferencesPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPAIPreferencesPage> createState() => _AISettingsState();
}

class _AISettingsState extends State<MLPAIPreferencesPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late String tone, voice;
  late bool contextAllowed;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final p = widget.e.ui.preferences;
    name = TextEditingController(text: p.nickname);
    tone = p.tone;
    voice = p.voice;
    contextAllowed = p.allowContext;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.e.ui.savePreferences(
        MLPUserPreferences.fromJson({
          ...widget.e.ui.preferences.toJson(),
          'nickname': name.text.trim(),
          'tone': tone,
          'voice': voice,
          'allowContext': contextAllowed,
        }),
      );
      if (mounted) MLPToast.show(context, 'Ustoz tanlovlari saqlandi.');
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Tanlovlar saqlanmadi. Qayta urinib ko‘ring.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return MLPPage(
      title: 'Ustozni moslash',
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: MLPColors.primaryLight,
            ),
          ),
        ),
        Text(
          'Sizga mos yordamchi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ustozning nomi va muloqot uslubini tanlang.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MLPColors.secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Form(
          key: form,
          child: Column(
            children: [
              MLPLiquidSurface(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SettingsCaption(
                      icon: Icons.face_retouching_natural_rounded,
                      title: 'Shaxsiyat va uslub',
                    ),
                    const SizedBox(height: 18),
                    MLPTextField(
                      controller: name,
                      label: 'Ustoz nomi',
                      maxLength: 30,
                      enabled: !busy,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nom kiriting.' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tone,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Muloqot uslubi',
                      ),
                      items:
                          ['Sodda va aniq', 'Qo‘llab-quvvatlovchi', 'Batafsil']
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: busy
                          ? null
                          : (v) => setState(() => tone = v ?? tone),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: voice,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ovoz tanlovi · demo',
                      ),
                      items:
                          {
                                'Standart (demo)',
                                'Sokin (demo)',
                                'Ravon (demo)',
                                voice,
                              }
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: busy
                          ? null
                          : (v) => setState(() => voice = v ?? voice),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              MLPLiquidSurface(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SettingsCaption(
                      icon: Icons.shield_outlined,
                      title: 'Maxfiylik',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mahalliy reja kontekstiga ruxsat',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          label: 'Mahalliy reja kontekstiga ruxsat',
                          child: CupertinoSwitch(
                            value: contextAllowed,
                            activeTrackColor: MLPColors.turquoise,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => contextAllowed = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Demo javobga vazifa nomi va mahalliy hisoblar qo‘shiladi. Serverga yuborilmaydi.',
                      style: TextStyle(
                        color: MLPColors.secondaryText,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const MLPNotice(
          'Mahalliy demo yordamchisi. Ushbu tanlovlar haqiqiy model, mikrofon yoki ovoz xizmatini yoqmaydi.',
        ),
        if (error != null) MLPNotice(error!, warning: true),
        MLPPrimaryButton(
          label: 'Ustoz tanlovlarini saqlash',
          busy: busy,
          onPressed: save,
        ),
        const SizedBox(height: 20),
        MLPMenuTile(
          title: 'AI ruxsatlari',
          subtitle: 'Mikrofon va tashqi xizmat ulanmagan',
          icon: Icons.shield_outlined,
          onTap: () => mlpShowDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: const Text('Ruxsatlar'),
              content: const SingleChildScrollView(
                child: Text(
                  'Mikrofon ruxsati so‘ralmagan. Kontaktlar, boshqa ilovalar va tizim ustidagi oynaga ruxsat yo‘q. Kontekst faqat yuqoridagi tanlov bilan demo javob uchun ishlatiladi.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Yopish'),
                ),
              ],
            ),
          ),
        ),
        MLPMenuTile(
          title: 'Suhbat tarixini tozalash',
          icon: Icons.delete_outline,
          onTap: () async {
            final yes = await MLPConfirmationSheet.show(
              context,
              title: 'Suhbat tozalansinmi?',
              message:
                  'Mahalliy chat tarixi o‘chadi. Maqsad va vazifalar saqlanadi.',
            );
            if (yes && context.mounted) {
              await e.act(
                context,
                e.ui.clearConversation,
                success: 'Suhbat tarixi tozalandi.',
              );
            }
          },
        ),
      ],
    );
  }
}

class _SettingsCaption extends StatelessWidget {
  const _SettingsCaption({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: MLPColors.primaryLight, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    ],
  );
}
