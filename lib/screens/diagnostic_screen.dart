import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/learning_goal.dart';
import '../models/learning_roadmap.dart';
import '../providers/app_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_scaffold.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key, required this.goal});

  final LearningGoal goal;

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _startDiagnostic();
  }

  Future<void> _startDiagnostic() async {
    _addSystemMessage("Salom! Siz ${widget.goal.title} bo'yicha o'z oldingizga aniq maqsad qo'yibsiz. Boshlashdan oldin bilimingizni biroz tahlil qilamiz.");
    
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _step = 1);
    
    _addSystemMessage("Sizning darajangiz: ${widget.goal.currentLevel}. Bunga qadar bu yo'nalishda qandaydir loyiha yoki mashqlar qilganmisiz? (Ha/Yo'q)");
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add({"role": "system", "text": text});
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({"role": "user", "text": text});
    });
  }

  Future<void> _handleUserResponse(String text) async {
    _addUserMessage(text);
    setState(() => _isTyping = true);
    
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isTyping = false);

    if (_step == 1) {
      _step = 2;
      _addSystemMessage("Tushunarli. Kuniga ${widget.goal.availableMinutesPerDay} daqiqa ajrata olarkansiz. Bu vaqt ichida ${widget.goal.outcome} maqsadiga erishish uchun men sizga moslashtirilgan o'quv rejasini (Roadmap) tuzib chiqaman.");
      
      await Future.delayed(const Duration(seconds: 2));
      _generateRoadmap();
    }
  }

  Future<void> _generateRoadmap() async {
    setState(() => _isTyping = true);
    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Save the goal to state
    context.read<AppState>().learningGoals.add(widget.goal);
    
    // Mock Roadmap generation
    final roadmap = LearningRoadmap(
      id: 'rm_${DateTime.now().millisecondsSinceEpoch}',
      goalId: widget.goal.id,
      createdAt: DateTime.now(),
      stages: [
        const LearningStage(
          id: 's1',
          title: 'Foundation (Asos)',
          objective: 'Asosiy tushunchalarni o\'zlashtirish',
          assessmentCriteria: '5 ta testdan o\'tish',
        ),
        const LearningStage(
          id: 's2',
          title: 'Amaliyot',
          objective: 'Kichik muammolarni hal qilish',
          assessmentCriteria: '1 ta mini loyiha',
        ),
        LearningStage(
          id: 's3',
          title: 'Yakuniy Natija',
          objective: widget.goal.outcome,
          assessmentCriteria: 'Asosiy loyihani topshirish',
        ),
      ],
    );
    
    context.read<AppState>().learningRoadmaps.add(roadmap);
    
    // Go to Roadmap screen (tab index 1)
    context.go('/roadmap');
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Ustoz Analizi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  return _buildMessageBubble(msg["text"], isUser);
                },
              ),
            ),
            if (_step == 1 && !_isTyping)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'Ha',
                        height: 50,
                        onPressed: () => _handleUserResponse("Ha, oldin harakat qilganman."),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Yo\'q',
                        height: 50,
                        colors: const [AppColors.surface2, AppColors.surface3],
                        onPressed: () => _handleUserResponse("Yo'q, mutlaqo noldan boshlayapman."),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const Text('Ustoz yozmoqda...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }
}
