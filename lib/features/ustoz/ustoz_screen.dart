import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/demo_banner.dart';

class UstozScreen extends ConsumerStatefulWidget {
  const UstozScreen({super.key});

  @override
  ConsumerState<UstozScreen> createState() => _UstozScreenState();
}

class _UstozScreenState extends ConsumerState<UstozScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  final _presets = [
    'Reja tuzishda yordam ber',
    'Motivatsiya kerak',
    'Vaqtni boshqarish usullari',
    'O\'rganish strategiyasi',
  ];

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() => _isSending = true);
    await ref.read(chatProvider.notifier).sendMessage(text);
    if (!mounted) return;
    setState(() => _isSending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: Column(
        children: [
          const DemoBanner(message: '⚠️ DEMO rejim — Skriptlangan AI javoblar'),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Ustoz', style: MlpTextStyles.h4),
                      Row(
                        children: [
                          Container(width: 8, height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: MlpColors.success,
                              )),
                          const SizedBox(width: 5),
                          Text('Online (Demo)', style: MlpTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(chatProvider.notifier).clear(),
                    child: const Icon(Icons.refresh_rounded, color: MlpColors.text3),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) {
                  return const _TypingBubble();
                }
                final msg = messages[i];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _send(_presets[i]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: MlpColors.bg3,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MlpColors.border),
                  ),
                  child: Text(_presets[i],
                      style: MlpTextStyles.caption.copyWith(color: MlpColors.text2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: MlpColors.text1, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Savol yozing...',
                        filled: true,
                        fillColor: MlpColors.bg2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: MlpColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: MlpColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: MlpColors.purple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _send(_ctrl.text),
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(
            colors: [MlpColors.purple, MlpColors.blue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
          color: isUser ? null : MlpColors.bg2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: MlpColors.border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : MlpColors.text1,
            fontSize: 14, height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MlpColors.bg2,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: MlpColors.border),
        ),
        child: const Text('Ustoz yozmoqda...', style: TextStyle(color: MlpColors.text3, fontSize: 13, fontStyle: FontStyle.italic)),
      ),
    );
  }
}
