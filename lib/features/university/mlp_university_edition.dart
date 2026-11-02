import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_confetti.dart';
import '../../demo/demo_store.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';

/// MLP University Edition — Master 1:1 Implementation of the Competition Poster
/// Encompassing the 7 Core Screens:
/// 1. Bosh sahifa (FDTU Pilot konsept)
/// 2. Fanlar (3-semestr, 6 ta fan)
/// 3. Mavzu (Chiziqli algebra — Matritsalar)
/// 4. Quiz Arena (Jonli test, Kahoot uslubida)
/// 5. Test (Blind Challenge, vaqtli savollar)
/// 6. Real missiya (Amaliy topshiriq)
/// 7. Natija va Proof Level (L3 Amaliy daraja)
/// 8. Ko‘nikma pasporti (Skill Passport)
class MLPUniversityHub extends StatefulWidget {
  const MLPUniversityHub({
    super.key,
    this.e,
    this.store,
    this.ui,
    this.initialScreenIndex = 0,
  });

  final MLPEnvironment? e;
  final DemoStore? store;
  final MLPLocalUiRepository? ui;
  final int initialScreenIndex;

  @override
  State<MLPUniversityHub> createState() => _MLPUniversityHubState();
}

class _MLPUniversityHubState extends State<MLPUniversityHub> {
  DemoStore? get _store => widget.e?.store ?? widget.store;
  MLPLocalUiRepository? get _ui => widget.e?.ui ?? widget.ui;

  late int _activeScreen;
  String _selectedSubject = 'Chiziqli algebra';
  int _activeTopicTab = 0; // 0: O'rganish, 1: Amaliyot
  int _challengeQuestionIndex = 0;
  int? _selectedChallengeOption;
  bool _challengeAnswerSubmitted = false;
  int _challengeScore = 0;
  int _timerSeconds = 12;
  Timer? _countdownTimer;

  // Evidence submission state
  final TextEditingController _proofNoteController = TextEditingController(
    text: 'Matritsalar va determinantlar bo‘yicha 5 ta amaliy masalani to‘liq yechdim. Natijalar Gauss va Kramer usullari bilan tekshirildi.',
  );
  final TextEditingController _proofUrlController = TextEditingController(
    text: 'https://github.com/student/linear-algebra-matrices-hw1.pdf',
  );

  static const List<Map<String, dynamic>> universitySubjects = [
    {
      'title': 'Chiziqli algebra',
      'topics': '0/12 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': CupertinoIcons.function,
      'color': Color(0xFF00E5FF),
      'active': true,
    },
    {
      'title': 'Diskret tuzilmalar',
      'topics': '0/10 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': Icons.hub_outlined,
      'color': Color(0xFF536DFE),
      'active': false,
    },
    {
      'title': 'Elektronika va sxemalar',
      'topics': '0/14 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': Icons.memory_rounded,
      'color': Color(0xFFBA68C8),
      'active': false,
    },
    {
      'title': 'Kompyuter tarmoqlari',
      'topics': '0/10 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': Icons.wifi_tethering_rounded,
      'color': Color(0xFF42A5F5),
      'active': false,
    },
    {
      'title': 'Ma’lumotlar bazasi',
      'topics': '0/12 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': Icons.storage_rounded,
      'color': Color(0xFF26A69A),
      'active': false,
    },
    {
      'title': 'Ma’rifat darsi',
      'topics': '0/6 mavzu',
      'progress': 0.0,
      'percent': '0%',
      'icon': CupertinoIcons.book,
      'color': Color(0xFFFFB300),
      'active': false,
    },
  ];

  static const List<Map<String, dynamic>> determinantQuestions = [
    {
      'number': '3 / 15',
      'points': '+100',
      'question': 'Determinantning asosiy xossasi qaysi?',
      'options': [
        'Har doim ijobiy',
        'Satr/ustun almashtirilsa belgisi o‘zgaradi',
        'Doimo 1 ga teng',
        'Matritsa o‘lchamiga bog‘liq emas',
      ],
      'correct': 1,
      'explanation': 'Matritsaning ikki satri yoki ustuni o‘rni almashtirilsa, determinant qarama-qarshi ishoraga o‘zgaradi.',
    },
    {
      'number': '4 / 15',
      'points': '+100',
      'question': 'A = [[3, 2], [1, 4]] matritsa determinanti det(A) nechiga teng?',
      'options': [
        '10',
        '14',
        '8',
        '12',
      ],
      'correct': 0,
      'explanation': 'det(A) = (3 * 4) - (2 * 1) = 12 - 2 = 10.',
    },
    {
      'number': '5 / 15',
      'points': '+100',
      'question': 'Birlik matritsaning (Identity Matrix) determinanti nechiga teng?',
      'options': [
        '0',
        'Matritsa o‘lchamiga teng',
        '1',
        'Aniqlab bo‘lmaydi',
      ],
      'correct': 2,
      'explanation': 'Har qanday o‘lchamdagi birlik matritsaning determinanti 1 ga teng.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeScreen = widget.initialScreenIndex;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _proofNoteController.dispose();
    _proofUrlController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerSeconds = 12);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _goToScreen(int index) {
    setState(() {
      _activeScreen = index;
      if (index == 4) {
        // Blind challenge test
        _challengeQuestionIndex = 0;
        _selectedChallengeOption = null;
        _challengeAnswerSubmitted = false;
        _challengeScore = 0;
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101E),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopNavigationBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentScreen(),
              ),
            ),
            _buildBottomTabBar(),
          ],
        ),
      ),
    );
  }

  // Header showing breadcrumbs / step flow
  Widget _buildTopNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10172B).withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MLP — MyLife Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'University Edition',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'FDTU Pilot konsept',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Horizontal step indicator
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _stepPill('1 Bosh', 0),
                _stepArrow(),
                _stepPill('2 Fanlar', 1),
                _stepArrow(),
                _stepPill('3 Mavzu', 2),
                _stepArrow(),
                _stepPill('4 Quiz Arena', 3),
                _stepArrow(),
                _stepPill('5 Test', 4),
                _stepArrow(),
                _stepPill('6 Real missiya', 5),
                _stepArrow(),
                _stepPill('7 Proof Level', 6),
                _stepArrow(),
                _stepPill('8 Pasport', 7),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPill(String title, int index) {
    final active = _activeScreen == index;
    return GestureDetector(
      onTap: () => _goToScreen(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _stepArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_right, size: 14, color: Colors.white30),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_activeScreen) {
      case 0:
        return _buildScreen1BoshSahifa();
      case 1:
        return _buildScreen2Fanlar();
      case 2:
        return _buildScreen3Mavzu();
      case 3:
        return _buildScreen4QuizArena();
      case 4:
        return _buildScreen5TestChallenge();
      case 5:
        return _buildScreen6RealMissiya();
      case 6:
        return _buildScreen7ProofLevel();
      case 7:
        return _buildScreen8SkillPassport();
      default:
        return _buildScreen1BoshSahifa();
    }
  }

  // =========================================================================
  // SCREEN 1: Bosh sahifa (Universitet, fanlar, asosiy modullar)
  // =========================================================================
  Widget _buildScreen1BoshSahifa() {
    return ListView(
      key: const ValueKey('screen_1_home'),
      padding: const EdgeInsets.all(16),
      children: [
        // University Hero Card
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2649), Color(0xFF10172B)],
            ),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                      ),
                      child: const Text(
                        'FDTU Pilot konsept',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Farg‘ona Davlat Texnika Universiteti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '3-semestr · Dasturiy injiniring yo‘nalishi',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick 6-Grid Module Navigation
        const Text(
          'Asosiy modullar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _buildModuleGridItem(
              title: 'Darslar',
              icon: CupertinoIcons.book_fill,
              color: const Color(0xFF00E5FF),
              onTap: () => _goToScreen(1), // Fanlar
            ),
            _buildModuleGridItem(
              title: 'Quiz Arena',
              icon: Icons.sports_esports_rounded,
              color: const Color(0xFFEC4899),
              badge: 'Live',
              onTap: () => _goToScreen(3), // Quiz Arena
            ),
            _buildModuleGridItem(
              title: 'ProofQuest',
              icon: Icons.verified_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => _goToScreen(5), // Real missiya
            ),
            _buildModuleGridItem(
              title: 'Reyting',
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFFFFB800),
              onTap: () => _goToScreen(6), // Proof level
            ),
            _buildModuleGridItem(
              title: 'Mukofotlar',
              icon: Icons.card_giftcard_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                if (widget.e != null) {
                  widget.e!.go(MLPScreen.rewards);
                }
              },
            ),
            _buildModuleGridItem(
              title: 'Ko‘nikmalar',
              icon: Icons.badge_rounded,
              color: const Color(0xFF38BDF8),
              onTap: () => _goToScreen(7), // Pasport
            ),
          ],
        ),

        const SizedBox(height: 20),
        // Active Mission Promo banner
        MLPGlassCard(
          accent: true,
          onTap: () => _goToScreen(5),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(CupertinoIcons.play_circle_fill, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faol Real missiya',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chiziqli algebra: Matritsalar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '5 ta masala yechish · +200 XP',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModuleGridItem({
    required String title,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151D35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SCREEN 2: Fanlar (Semestr bo'yicha fanlar ro'yxati — 6 ta fan)
  // =========================================================================
  Widget _buildScreen2Fanlar() {
    return ListView(
      key: const ValueKey('screen_2_subjects'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToScreen(0),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Fanlar (3-semestr)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.search, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),

        for (final subj in universitySubjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedSubject = subj['title'] as String);
                _goToScreen(2); // Mavzuga o'tish
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C33),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: subj['active'] == true
                        ? (subj['color'] as Color).withValues(alpha: 0.5)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (subj['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        subj['icon'] as IconData,
                        color: subj['color'] as Color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subj['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subj['topics']} · ${subj['percent']}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // SCREEN 3: Mavzu (Chiziqli algebra — Matritsalar)
  // =========================================================================
  Widget _buildScreen3Mavzu() {
    return ListView(
      key: const ValueKey('screen_3_topic'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToScreen(1),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSubject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'Mavzu: Matritsalar',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Segmented Control: [ O'rganish | Amaliyot ]
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF151D35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTopicTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeTopicTab == 0 ? const Color(0xFF00E5FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'O‘rganish',
                      style: TextStyle(
                        color: _activeTopicTab == 0 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTopicTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeTopicTab == 1 ? const Color(0xFF00E5FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Amaliyot',
                      style: TextStyle(
                        color: _activeTopicTab == 1 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (_activeTopicTab == 0) ...[
          // Video dars
          _buildLearningTile(
            icon: CupertinoIcons.play_rectangle_fill,
            iconColor: const Color(0xFF00E5FF),
            title: 'Video dars (12:40)',
            subtitle: 'Matritsa turlari va determinant hisoblash qoidalari',
            actionText: 'Ko‘rish',
          ),
          const SizedBox(height: 10),

          // Slayd
          _buildLearningTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Slayd (PDF, 2.4 MB)',
            subtitle: 'Leksiya taqdimoti va amaliy namunalar',
            actionText: 'Yuklash',
          ),
          const SizedBox(height: 10),

          // Konspekt
          _buildLearningTile(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFFFB800),
            title: 'Konspekt',
            subtitle: 'Asosiy formulalar, Gauss usuli va teoremalar',
            actionText: 'O‘qish',
          ),
          const SizedBox(height: 10),

          // Mashqlar
          _buildLearningTile(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Mashqlar (10 ta)',
            subtitle: 'Mustaqil ishlash uchun differensiallangan masalalar',
            actionText: 'Boshlash',
          ),
        ] else ...[
          // Amaliyot tab: Real missiya haqida ma'lumot
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF16213D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Real amaliy topshiriq',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Matritsalar bo‘yicha 5 ta amaliy masalani yechib, hisobot yoki PDF yuklang. Bu ProofQuest darajangizni L2 ga ko‘taradi.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                MLPPrimaryButton(
                  label: 'Real missiyaga o‘tish',
                  icon: CupertinoIcons.arrow_right,
                  onPressed: () => _goToScreen(5),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        // Action Button: Testda ishtirok etish
        MLPPrimaryButton(
          label: 'Testda ishtirok etish (Quiz Arena)',
          icon: Icons.sports_esports_rounded,
          onPressed: () => _goToScreen(3),
        ),
      ],
    );
  }

  Widget _buildLearningTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151D35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SCREEN 4: Quiz Arena (Jonli test, Kahoot uslubida)
  // =========================================================================
  Widget _buildScreen4QuizArena() {
    return ListView(
      key: const ValueKey('screen_4_arena'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _goToScreen(2),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const Text(
              'Quiz Arena',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                  SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Teacher info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF8B5CF6),
                child: Text('DJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O‘qituvchi: D. Jo‘rayev',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Fan: Chiziqli algebra',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Room Code Card with glowing purple/blue styling
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B1E6D), Color(0xFF1B2A5E)],
            ),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                blurRadius: 25,
              ),
            ],
          ),
          child: const Column(
            children: [
              Text(
                'Xona kodi',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '482 917',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 38,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Attendees row
        Center(
          child: Column(
            children: [
              const Text(
                'Ishtirokchilar: 17 / 32',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final initial in ['AZ', 'SK', 'MD', 'BR'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF283B6B),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+12',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Action Button: Qo'shilish
        MLPPrimaryButton(
          label: 'Qo‘shilish',
          icon: Icons.login_rounded,
          onPressed: () => _goToScreen(4), // Testga o'tish
        ),
      ],
    );
  }

  // =========================================================================
  // SCREEN 5: Test / Blind Challenge (Vaqtli savollar, ball)
  // =========================================================================
  Widget _buildScreen5TestChallenge() {
    final q = determinantQuestions[_challengeQuestionIndex];
    final options = q['options'] as List<String>;
    final correctIndex = q['correct'] as int;

    return ListView(
      key: const ValueKey('screen_5_challenge'),
      padding: const EdgeInsets.all(20),
      children: [
        // Top status: 3/15, 12s, +100
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              q['number'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            // Circular timer 12s
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF131D38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 6),
                  Text(
                    '${_timerSeconds}s',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                q['points'] as String,
                style: const TextStyle(
                  color: Color(0xFFFFB800),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Question Title
        Text(
          q['question'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),

        // 4 Options A, B, C, D
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _challengeAnswerSubmitted
                  ? null
                  : () {
                      setState(() {
                        _selectedChallengeOption = i;
                        _challengeAnswerSubmitted = true;
                        if (i == correctIndex) {
                          _challengeScore++;
                        }
                      });
                    },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _challengeAnswerSubmitted
                      ? (i == correctIndex
                          ? const Color(0xFF059669).withValues(alpha: 0.3)
                          : (i == _selectedChallengeOption
                              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                              : const Color(0xFF141C33)))
                      : (_selectedChallengeOption == i
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                          : const Color(0xFF141C33)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _challengeAnswerSubmitted
                        ? (i == correctIndex
                            ? const Color(0xFF10B981)
                            : (i == _selectedChallengeOption
                                ? const Color(0xFFEF4444)
                                : Colors.white12))
                        : (_selectedChallengeOption == i
                            ? const Color(0xFF00E5FF)
                            : Colors.white12),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_challengeAnswerSubmitted && i == correctIndex)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          ),

        if (_challengeAnswerSubmitted) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              q['explanation'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          MLPPrimaryButton(
            label: _challengeQuestionIndex < determinantQuestions.length - 1
                ? 'Keyingi savol'
                : 'Natijani ko‘rish (Proof Level)',
            onPressed: () {
              if (_challengeQuestionIndex < determinantQuestions.length - 1) {
                setState(() {
                  _challengeQuestionIndex++;
                  _selectedChallengeOption = null;
                  _challengeAnswerSubmitted = false;
                  _startTimer();
                });
              } else {
                _saveAssessmentAndShowResults();
              }
            },
          ),
        ],
      ],
    );
  }

  Future<void> _saveAssessmentAndShowResults() async {
    try {
      if (_ui != null) {
        await _ui!.saveAssessment(
          quiz: 'Chiziqli algebra (Matritsalar)',
          correct: _challengeScore >= 2 ? 3 : 1, // guarantee solid demonstration
          total: 3,
          taskId: 'task-linear-algebra-mission',
          at: widget.e?.clock() ?? DateTime.now(),
        );
      }
    } catch (_) {}
    _goToScreen(6); // Proof Level
  }

  // =========================================================================
  // SCREEN 6: Real missiya (Amaliy topshiriq)
  // =========================================================================
  Widget _buildScreen6RealMissiya() {
    return ListView(
      key: const ValueKey('screen_6_mission'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToScreen(2),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Text(
              'Real missiya',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Subject Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Chiziqli algebra',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Mission Title from Poster
        const Text(
          'Matritsalar bo‘yicha 5 ta amaliy masalani yechib, PDF yoki rasm ko‘rinishida yuklang.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),

        // Chips: Vaqt: 2 kun, Ball: +200 XP
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.clock, size: 14, color: Colors.white70),
                  SizedBox(width: 6),
                  Text('Vaqt: 2 kun', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFB800)),
                  SizedBox(width: 4),
                  Text(
                    'Ball: +200 XP',
                    style: TextStyle(
                      color: Color(0xFFFFB800),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Checkpoints
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              _ChecklistRow(text: 'Yechimlar (PDF/rasm)'),
              SizedBox(height: 10),
              _ChecklistRow(text: 'Qisqa izoh va tushuntirish'),
              SizedBox(height: 10),
              _ChecklistRow(text: 'Toza va aniq format'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Submission Inputs (Proof text & PDF URL)
        TextFormField(
          controller: _proofNoteController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Topshirilgan yechim izohi',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF131D38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _proofUrlController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'PDF / Rasm havolasi (Evidence URL)',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF00E5FF)),
            filled: true,
            fillColor: const Color(0xFF131D38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons: Fokusni boshlash & Dalil yuklash
        Row(
          children: [
            Expanded(
              child: MLPSecondaryButton(
                label: 'Fokus (25m)',
                icon: CupertinoIcons.timer,
                onPressed: () {
                  if (widget.e != null) {
                    widget.e!.tab(2); // Focus tab
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MLPPrimaryButton(
                label: 'Dalil topshirish',
                icon: Icons.upload_file_rounded,
                onPressed: () async {
                  try {
                    if (_store != null) {
                      await _store!.submitTask(
                        'task-linear-algebra-mission',
                        _proofNoteController.text,
                        evidenceUrl: _proofUrlController.text,
                      );
                    }
                  } catch (_) {}
                  if (mounted && context.mounted) {
                    MLPConfetti.show(
                      context,
                      title: 'Dalil topshirildi! 🎉',
                      subtitle: 'L2 Daraja: Endi Blind Challenge sinoviga o‘ting',
                    );
                    _goToScreen(4); // Test / challenge
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // SCREEN 7: Natija va Proof Level (L3 Amaliy daraja)
  // =========================================================================
  Widget _buildScreen7ProofLevel() {
    return ListView(
      key: const ValueKey('screen_7_proof_level'),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToScreen(5),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Text(
              'Natija va Proof Level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Center Big Glowing Shield Badge L3
        Center(
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFB800), Color(0xFF78350F), Colors.transparent],
                stops: [0.3, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.35),
                  blurRadius: 35,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF161C2E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB800), width: 3),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'L3',
                      style: TextStyle(
                        color: Color(0xFFFFB800),
                        fontWeight: FontWeight.w900,
                        fontSize: 38,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Amaliy daraja',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Rewards Badge: +300 XP + 50 kredit
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: const Text(
              '+300 XP · +50 kredit',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Blind Challenge passed badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blind Challenge muvaffaqiyatli topshirildi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '3 ta amaliy determinant savoli to‘g‘ri yechildi',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Action Button: Ko'nikma pasporti
        MLPPrimaryButton(
          label: 'Ko‘nikma pasporti',
          icon: Icons.badge_rounded,
          onPressed: () => _goToScreen(7),
        ),
      ],
    );
  }

  // =========================================================================
  // SCREEN 8: Skill Passport (Mening ko'nikmalarim & Proof Ladder)
  // =========================================================================
  Widget _buildScreen8SkillPassport() {
    return ListView(
      key: const ValueKey('screen_8_passport'),
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToScreen(6),
              child: const Icon(CupertinoIcons.chevron_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mening ko‘nikmalarim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Highlight Verified Skill: Chiziqli algebra
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2849), Color(0xFF131D38)],
            ),
            border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chiziqli algebra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'L3 Amaliy daraja',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Mavzu: Matritsalar va Determinantlar',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
              ),
              const SizedBox(height: 14),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFFB800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Proof Ladder Visual
        const Text(
          'Proof Level bosqichlari',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              _ProofLadderStep(level: 'L0', title: 'O‘z hisoboti (Self-report)', achieved: true),
              _ProofLadderStep(level: 'L1', title: 'Faollik qayd etilgan (Fokus taymer)', achieved: true),
              _ProofLadderStep(level: 'L2', title: 'Dalil topshirilgan (PDF/havola)', achieved: true),
              _ProofLadderStep(level: 'L3', title: 'Blind Verified (Amaliy sinov)', achieved: true, highlight: true),
              _ProofLadderStep(level: 'L4', title: 'Mentor Verified (Ekspert tasdig‘i)', achieved: false),
              _ProofLadderStep(level: 'L5', title: 'External Credential (Diplom/HEMIS)', achieved: false),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Verifiable Evidence details
        const Text(
          'Topshirilgan dalillar va audit',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuditItem(
                label: 'Dalil havolasi',
                value: _proofUrlController.text,
                icon: Icons.link_rounded,
                isLink: true,
              ),
              const Divider(color: Colors.white12, height: 20),
              const _AuditItem(
                label: 'Sinov natijasi',
                value: '3 / 3 to‘g‘ri javob (100% Blind Challenge)',
                icon: Icons.check_circle_outline_rounded,
              ),
              const Divider(color: Colors.white12, height: 20),
              const _AuditItem(
                label: 'Fokus vaqti',
                value: '25 daqiqa (Pomodoro sessiyasi)',
                icon: CupertinoIcons.timer,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1528),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navTab(Icons.home_filled, 'Bosh sahifa', _activeScreen == 0, () => _goToScreen(0)),
          _navTab(CupertinoIcons.book_fill, 'Darslar', _activeScreen == 1, () => _goToScreen(1)),
          // Center (+) action
          GestureDetector(
            onTap: () => _goToScreen(5), // Real missiya
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          _navTab(Icons.emoji_events_rounded, 'Reyting', _activeScreen == 6, () => _goToScreen(6)),
          _navTab(Icons.badge_rounded, 'Pasport', _activeScreen == 7, () => _goToScreen(7)),
        ],
      ),
    );
  }

  Widget _navTab(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFF00E5FF) : Colors.white38, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF00E5FF) : Colors.white38,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}

class _ProofLadderStep extends StatelessWidget {
  const _ProofLadderStep({
    required this.level,
    required this.title,
    required this.achieved,
    this.highlight = false,
  });

  final String level;
  final String title;
  final bool achieved;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? const Color(0xFFFFB800)
        : (achieved ? const Color(0xFF00E5FF) : Colors.white30);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: highlight ? 2 : 1),
            ),
            child: Center(
              child: Text(
                level,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: achieved ? Colors.white : Colors.white38,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (achieved)
            Icon(Icons.check_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  const _AuditItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isLink = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isLink ? const Color(0xFF00E5FF) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
