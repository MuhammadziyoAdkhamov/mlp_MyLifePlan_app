import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatLog = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _chatLog.add({
      'role': 'ai',
      'text': 'Salom! Men sizning shaxsiy AI ustozingizman. O‘rganish bo‘yicha qanday yordam bera olaman?'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatLog.add({'role': 'user', 'text': text});
      _controller.clear();
      _isTyping = true;
    });

    // Simulate AI response
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = false;
      _chatLog.add({
        'role': 'ai',
        'text': 'Bu ajoyib savol. Hozircha men Beta rejimdaman va faqat loyihaning Frontend qismida simulyatsiya sifatida ishlayapman. Tez orada backend ga ulanaman!'
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSoft.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Ustoz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald),
                        ),
                        const SizedBox(width: 6),
                        const Text('Online (Beta)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _chatLog.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatLog.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('AI o‘ylamoqda...', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                    ),
                  );
                }
                
                final msg = _chatLog[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Savol bering...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface2,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
