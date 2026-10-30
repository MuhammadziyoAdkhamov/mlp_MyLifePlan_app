import 'package:uuid/uuid.dart';
import '../domain/goal_model.dart';
import '../domain/roadmap_model.dart';
import '../domain/lesson_model.dart';
import '../domain/reward_model.dart';

const _uuid = Uuid();

class MockData {
  const MockData._();

  static List<RewardItem> get rewards => [
        const RewardItem(
          id: 'r1', emoji: '☕', title: 'Kofe Chegirma',
          description: 'Yaqinlashdagi kafe da 15% chegirma. Demo katalog.',
          coinCost: 100,
        ),
        const RewardItem(
          id: 'r2', emoji: '📚', title: 'Kitob Kupon',
          description: 'Online kitob do\'konida 20% chegirma. Demo.',
          coinCost: 200,
        ),
        const RewardItem(
          id: 'r3', emoji: '🎧', title: 'Premium Kurs',
          description: 'Tanlangan kursda 1 hafta bepul. Demo.',
          coinCost: 500,
        ),
        const RewardItem(
          id: 'r4', emoji: '🏆', title: 'Maxsus Nishon',
          description: 'Profilizda ko\'rinadigan maxsus nishon. Demo.',
          coinCost: 150,
        ),
      ];

  /// Generate a roadmap for a given goal
  static MlpRoadmap generateRoadmap(MlpGoal goal) {
    final roadmapId = _uuid.v4();
    final milestones = _milestonesForCategory(goal);
    return MlpRoadmap(
      id: roadmapId,
      goalId: goal.id,
      milestones: milestones,
      createdAt: DateTime.now(),
      totalEstimatedDays: milestones.fold(0, (sum, m) => sum + m.estimatedDays),
    );
  }

  static List<MlpMilestone> _milestonesForCategory(MlpGoal goal) {
    switch (goal.category) {
      case GoalCategory.til:
        return [
          MlpMilestone(
            id: _uuid.v4(), title: 'Asos (Foundation)',
            objective: 'Asosiy so\'z boyligini va grammatika qoidalarini o\'rganish',
            estimatedDays: 10, assessmentCriteria: '50 ta yangi so\'z va asosiy jumlalar',
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'Salomlashish jumlalari', xpReward: 15),
              MlpTask(id: _uuid.v4(), title: 'Asosiy fe\'l va ot', xpReward: 20),
              MlpTask(id: _uuid.v4(), title: 'Raqamlar va ranglar', xpReward: 10),
            ],
          ),
          MlpMilestone(
            id: _uuid.v4(), title: 'Amaliyot (Practice)',
            objective: 'Kundalik suhbatlarni mashq qilish',
            estimatedDays: 14, assessmentCriteria: '5 ta mini suhbat',
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'O\'zingni tanishtir', xpReward: 20),
              MlpTask(id: _uuid.v4(), title: 'Do\'stlar bilan suhbat', xpReward: 25),
              MlpTask(id: _uuid.v4(), title: 'Audio tinglash', xpReward: 15),
            ],
          ),
          MlpMilestone(
            id: _uuid.v4(), title: 'Yakuniy Natija',
            objective: goal.outcome,
            estimatedDays: 20, assessmentCriteria: 'Mini test: ${goal.outcome}',
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'Mock test yechish', xpReward: 50),
              MlpTask(id: _uuid.v4(), title: 'O\'z xatolarni tahlil qilish', xpReward: 30),
            ],
          ),
        ];
      case GoalCategory.dasturlash:
        return [
          MlpMilestone(
            id: _uuid.v4(), title: 'Asoslar',
            objective: 'Dasturlash tushunchalarini o\'zlashtirish',
            estimatedDays: 14,
            assessmentCriteria: 'Hello World + oddiy kalkulyator',
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'O\'zgaruvchilar va turlar', xpReward: 20),
              MlpTask(id: _uuid.v4(), title: 'Shartlar va tsikllar', xpReward: 25),
              MlpTask(id: _uuid.v4(), title: 'Funksiyalar', xpReward: 20),
            ],
          ),
          MlpMilestone(
            id: _uuid.v4(), title: 'Mini Loyiha',
            objective: 'Birinchi haqiqiy loyiha yaratish',
            estimatedDays: 21,
            assessmentCriteria: goal.outcome,
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'Loyiha rejasini tuzish', xpReward: 30),
              MlpTask(id: _uuid.v4(), title: 'Asosiy funksiyalarni yozish', xpReward: 50),
              MlpTask(id: _uuid.v4(), title: 'Loyihani test qilish', xpReward: 40),
            ],
          ),
        ];
      default:
        return [
          MlpMilestone(
            id: _uuid.v4(), title: 'Boshlash',
            objective: 'Asoslarni o\'rganish va reja tuzish',
            estimatedDays: 7,
            assessmentCriteria: 'Reja va birinchi qadam',
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'Maqsadni aniqlashtirish', xpReward: 15),
              MlpTask(id: _uuid.v4(), title: 'Resurslarni topish', xpReward: 20),
              MlpTask(id: _uuid.v4(), title: 'Birinchi kichik qadam', xpReward: 25),
            ],
          ),
          MlpMilestone(
            id: _uuid.v4(), title: 'Rivojlanish',
            objective: goal.outcome,
            estimatedDays: 21,
            assessmentCriteria: goal.outcome,
            tasks: [
              MlpTask(id: _uuid.v4(), title: 'Muntazam mashq', xpReward: 30),
              MlpTask(id: _uuid.v4(), title: 'Natijani baholash', xpReward: 25),
              MlpTask(id: _uuid.v4(), title: 'Keyingi bosqich rejasi', xpReward: 20),
            ],
          ),
        ];
    }
  }

  static List<MlpLesson> lessonsForMilestone(String milestoneId, String milestoneTitle) {
    return [
      MlpLesson(
        id: _uuid.v4(), milestoneId: milestoneId,
        title: '$milestoneTitle: Kirish darsi',
        content: '''Bu bosqichda siz **$milestoneTitle** mavzusini o'rganasiz.\n\nHar bir dars 3 qismdan iborat:\n1. 📖 **O'qish** — Asosiy tushunchalar\n2. 🧪 **Amaliyot** — Vazifa bajarish\n3. ✅ **Tekshirish** — Bilimingizni sinab ko'ring\n\nBu tizim sizga bilimni chuqurroq o'zlashtirishga yordam beradi.''',
        practicalTask: 'Ushbu mavzu bo\'yicha o\'z so\'zlaringiz bilan 3 ta asosiy tushunchani yozing.',
        questions: const [
          LessonQuestion(
            id: 'q1', question: 'Ushbu darsda nima o\'rgandingiz?',
            type: QuestionType.multipleChoice,
            options: ['Yangi tushunchalarni', 'Hech narsa', 'Faqat nazariya', 'Faqat amaliyot'],
            correctIndex: 0,
            explanation: 'Dars nazariya va amaliyotni birlashtiradi.',
          ),
        ],
        xpReward: 50, estimatedMinutes: 15,
      ),
      MlpLesson(
        id: _uuid.v4(), milestoneId: milestoneId,
        title: '$milestoneTitle: Chuqurlashtirish',
        content: '''Oldingi darsda asosiy tushunchalar bilan tanishdingiz.\n\nEndi **amaliy ko'nikmalar** ga o'tamiz:\n\n- Birinchi qadam: Tushunchani o'zingizga izohlab bering\n- Ikkinchi qadam: Kichik misol yarating\n- Uchinchi qadam: Xatolaringizni tahlil qiling\n\n> 💡 Yodda tuting: Xato — bu o'rganishning eng yaxshi usuli.''',
        practicalTask: 'Ushbu mavzu bo\'yicha haqiqiy hayotdan bitta misol keltiring va nima uchun muhimligini tushuntiring.',
        questions: const [
          LessonQuestion(
            id: 'q2', question: 'Amaliyot qanday yordam beradi?',
            type: QuestionType.multipleChoice,
            options: ['Hech qanday', 'Bilimni mustahkamlaydi', 'Vaqt sarflaydi', 'Faqat o\'qish kifoya'],
            correctIndex: 1,
            explanation: 'Amaliyot bilimni uzoq muddatli xotiraga o\'tkazadi.',
          ),
        ],
        xpReward: 75, estimatedMinutes: 20,
      ),
    ];
  }

  static const List<Map<String, String>> aiScripts = [
    {
      'trigger': 'reja',
      'response': '📋 Reja tuzish uchun avval **maqsadingizni** aniq belgilang. Keyin uni kichik, bajariladigan qadamlarga bo\'ling. Har bir qadam maksimum 1-2 soat davom etsin.',
    },
    {
      'trigger': 'xato',
      'response': '🔍 Xato tabiiy holat. Eng muhimi — **xatongizni tahlil qilish**. Nima noto\'g\'ri ketdi? Nima o\'zgartirish mumkin? Bu savollar sizni oldinga olib boradi.',
    },
    {
      'trigger': 'o\'rganish',
      'response': '📚 O\'rganishning eng samarali usuli — **faol takrorlash** (active recall). Faqat o\'qish emas, balki o\'z so\'zlaringiz bilan tushuntirish bilimni mustahkamlaydi.',
    },
    {
      'trigger': 'vaqt',
      'response': '⏰ Vaqtni boshqarish uchun **Pomodoro texnikasi** ni sinab ko\'ring: 25 daqiqa ishlash + 5 daqiqa tanaffus. Bu fokusni keskin oshiradi.',
    },
    {
      'trigger': 'motivatsiya',
      'response': '🔥 Motivatsiya beqaror, **intizom** — doimiy. Har kuni faqat 5 daqiqa bajaring — bu odatni shakllantiradi. Odatdan so\'ng motivatsiya o\'zi keladi.',
    },
  ];

  static String getAiResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    for (final script in aiScripts) {
      if (lower.contains(script['trigger']!)) {
        return script['response']!;
      }
    }
    return '🤔 Savolingizni tushundim. Yordam berish uchun ko\'proq tafsilot bering. Masalan: Qaysi mavzuda qiyinchilik bor? Nima maqsad qo\'ygan edingiz?\n\n_⚠️ Demo rejim: Haqiqiy AI ulanmagan_';
  }
}
