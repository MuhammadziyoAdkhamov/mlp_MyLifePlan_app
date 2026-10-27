import 'package:flutter/material.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/repositories/mlp_ui_repository.dart';

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
  });
  final MLPEnvironment e;
  final MLPAssistantAdapter adapter;
  @override
  State<MLPChatPage> createState() => _ChatState();
}

class _ChatState extends State<MLPChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  String? error, pending;
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
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: MLPDimensions.motion(context),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Demo javob yoki suhbat saqlanmadi. Qayta urinib ko‘ring.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.e.ui,
    builder: (context, _) {
      final e = widget.e, messages = widget.e.ui.messages;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.ui.preferences.nickname,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Ovozli suhbat ko‘rinishi',
                  onPressed: () => e.go(MLPScreen.voice),
                  icon: const Icon(Icons.mic_none_rounded),
                ),
                IconButton(
                  tooltip: 'Ustozni moslash',
                  onPressed: () => e.go(MLPScreen.aiPersonalization),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    children: [
                      const MLPNotice(
                        'Demo suhbat · jonli AI ulanmagan. Oxirgi 100 xabar shu qurilmada saqlanadi.',
                      ),
                      if (messages.isEmpty) ...[
                        MLPAvatarOrb(
                          state: busy ? MLPOrbState.thinking : MLPOrbState.idle,
                          size: 100,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Salom! Men ${e.ui.preferences.nickname}.',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kichik qadamingizni birga aniqlaymiz.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ...[
                          'Bugungi rejamni tahlil qil.',
                          'Vazifamni osonlashtir.',
                          'Nega ortda qolyapman?',
                          'Ertangi kunimni rejalashtir.',
                          'Flutter mavzusini tushuntir.',
                        ].map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MLPSecondaryButton(
                              label: q,
                              onPressed: busy ? null : () => send(q),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }
                if (i == messages.length + 1) {
                  return Column(
                    children: [
                      if (busy)
                        const MLPLoadingState(
                          label: 'Demo javob tayyorlanmoqda…',
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
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxWidth: 620),
                    decoration: BoxDecoration(
                      color: mine
                          ? MLPColors.primary.withValues(alpha: .18)
                          : MLPColors.secondary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(mine ? 20 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 20),
                      ),
                      border: Border.all(color: MLPColors.border),
                    ),
                    child: SelectableText(
                      '${message['text']}',
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 1000,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        hintText: 'Savolingizni yozing…',
                        counterText: '',
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MLPIconButton(
                    label: 'Xabarni yuborish',
                    icon: busy ? Icons.hourglass_top : Icons.send_rounded,
                    onPressed: busy ? null : () => send(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
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
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.e.ui,
    builder: (context, _) {
      final e = widget.e, muted = widget.e.ui.preferences.muted;
      return MLPPage(
        title: 'Ovozli suhbat',
        children: [
          const MLPNotice(
            'Interfeys namoyishi. Mikrofon yoqilmadi; STT/TTS va haqiqiy ovozli javob ulanmagan.',
          ),
          const SizedBox(height: 24),
          Center(
            child: MLPAvatarOrb(
              size: 180,
              state: muted ? MLPOrbState.muted : state,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'USTOZ AI — ${e.ui.preferences.nickname}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                (MLPOrbState.listening, 'Tinglash ko‘rinishi'),
                (MLPOrbState.thinking, 'O‘ylash ko‘rinishi'),
                (MLPOrbState.speaking, 'Javob ko‘rinishi'),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: state == entry.$1 && !muted,
                  onSelected: muted
                      ? null
                      : (_) => setState(() => state = entry.$1),
                ),
            ],
          ),
          const SizedBox(height: 24),
          MLPSecondaryButton(
            label: muted
                ? 'Demo ovoz holatini yoqish'
                : 'Demo ovoz holatini o‘chirish',
            icon: muted ? Icons.mic_off : Icons.mic_none,
            onPressed: () => e.act(
              context,
              () => e.ui.savePreferences(
                MLPUserPreferences.fromJson({
                  ...e.ui.preferences.toJson(),
                  'muted': !muted,
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MLPPrimaryButton(
            label: 'Suhbatni tugatish va chatga qaytish',
            onPressed: () {
              setState(() => state = MLPOrbState.idle);
              e.tab(3);
            },
          ),
          const SizedBox(height: 24),
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
                  child: MLPGlassCard(
                    child: Text(
                      '${m['role'] == 'user' ? 'Siz' : e.ui.preferences.nickname}: ${m['text']}',
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

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return MLPPage(
      title: 'Ustozni moslash',
      children: [
        const MLPNotice(
          'Mahalliy demo yordamchisi. Ushbu tanlovlar haqiqiy model, mikrofon yoki ovoz xizmatini yoqmaydi.',
        ),
        Form(
          key: form,
          child: Column(
            children: [
              MLPTextField(
                controller: name,
                label: 'Ustoz nomi',
                maxLength: 30,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nom kiriting.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: tone,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Muloqot uslubi'),
                items: ['Sodda va aniq', 'Qo‘llab-quvvatlovchi', 'Batafsil']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => tone = v ?? tone),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: voice,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ovoz tanlovi · demo',
                ),
                items:
                    {'Standart (demo)', 'Sokin (demo)', 'Ravon (demo)', voice}
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => voice = v ?? voice),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: contextAllowed,
                title: const Text('Mahalliy reja kontekstiga ruxsat'),
                subtitle: const Text(
                  'Demo javobga vazifa nomi va mahalliy hisoblar qo‘shiladi. Serverga yuborilmaydi.',
                ),
                onChanged: (v) => setState(() => contextAllowed = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (error != null) MLPNotice(error!, warning: true),
        MLPPrimaryButton(
          label: 'Ustoz tanlovlarini saqlash',
          busy: busy,
          onPressed: () async {
            if (!form.currentState!.validate() || busy) return;
            setState(() {
              busy = true;
              error = null;
            });
            try {
              await e.ui.savePreferences(
                MLPUserPreferences.fromJson({
                  ...e.ui.preferences.toJson(),
                  'nickname': name.text.trim(),
                  'tone': tone,
                  'voice': voice,
                  'allowContext': contextAllowed,
                }),
              );
              if (context.mounted) {
                MLPToast.show(context, 'Ustoz tanlovlari saqlandi.');
              }
            } catch (_) {
              if (mounted) {
                setState(
                  () => error = 'Tanlovlar saqlanmadi. Qayta urinib ko‘ring.',
                );
              }
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
        ),
        const SizedBox(height: 20),
        MLPMenuTile(
          title: 'AI ruxsatlari',
          subtitle: 'Mikrofon va tashqi xizmat ulanmagan',
          icon: Icons.shield_outlined,
          onTap: () => e.info(
            context,
            'Ruxsatlar',
            'Mikrofon ruxsati so‘ralmagan. Kontaktlar, boshqa ilovalar va tizim ustidagi oynaga ruxsat yo‘q. Kontekst faqat yuqoridagi tanlov bilan demo javob uchun ishlatiladi.',
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
