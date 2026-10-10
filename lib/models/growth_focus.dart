import 'habit_enums.dart';

enum GrowthFocus { focus, energy, calm, consistency }

class StarterHabitSpec {
  const StarterHabitSpec({
    required this.name,
    required this.goal,
    required this.minimalGoal,
    required this.whyNote,
    required this.category,
  });

  final String name;
  final String goal;
  final String minimalGoal;
  final String whyNote;
  final HabitCategory category;
}

extension GrowthFocusX on GrowthFocus {
  String get label => switch (this) {
    GrowthFocus.focus => 'Fokus va o‘qish',
    GrowthFocus.energy => 'Quvvat va sog‘liq',
    GrowthFocus.calm => 'Xotirjamlik',
    GrowthFocus.consistency => 'Barqarorlik',
  };

  String get description => switch (this) {
    GrowthFocus.focus => 'Diqqatni jamlash va o‘rganish uchun',
    GrowthFocus.energy => 'Tana va kunlik energiya uchun',
    GrowthFocus.calm => 'Stressni kamaytirib, o‘zingga vaqt ajratish uchun',
    GrowthFocus.consistency => 'Kichik ishlarni muntazam qilish uchun',
  };

  List<StarterHabitSpec> get starterHabits => switch (this) {
    GrowthFocus.focus => const [
      StarterHabitSpec(
        name: '25 daqiqa diqqat bilan ishlash',
        goal: '25 daqiqa',
        minimalGoal: 'Vazifani 2 daqiqa ochib ko‘rish',
        whyNote: 'Har kuni ozgina bo‘lsa ham oldinga yurish',
        category: HabitCategory.study,
      ),
      StarterHabitSpec(
        name: '5 sahifa o‘qish',
        goal: '5 sahifa',
        minimalGoal: '1 sahifa o‘qish',
        whyNote: 'Bilimni kichik qadamlar bilan oshirish',
        category: HabitCategory.study,
      ),
      StarterHabitSpec(
        name: 'Ertangi kunni rejalash',
        goal: 'Ertangi 1 muhim vazifa',
        minimalGoal: 'Bitta ustuvor ishni yozish',
        whyNote: 'Kunimni maqsad bilan boshlash',
        category: HabitCategory.mind,
      ),
    ],
    GrowthFocus.energy => const [
      StarterHabitSpec(
        name: 'Suv ichish',
        goal: '6 stakan',
        minimalGoal: '1 stakan suv',
        whyNote: 'Tanamga kerakli energiyani berish',
        category: HabitCategory.health,
      ),
      StarterHabitSpec(
        name: '10 daqiqa yurish',
        goal: '10 daqiqa',
        minimalGoal: '2 daqiqa harakat',
        whyNote: 'Harakat orqali o‘zimni tetik his qilish',
        category: HabitCategory.health,
      ),
      StarterHabitSpec(
        name: 'Uyquga tayyorgarlik',
        goal: '15 daqiqa ekransiz',
        minimalGoal: 'Telefonni 2 daqiqaga chetga qo‘yish',
        whyNote: 'Yaxshi dam olish uchun kechani tinch yakunlash',
        category: HabitCategory.mind,
      ),
    ],
    GrowthFocus.calm => const [
      StarterHabitSpec(
        name: 'Nafas mashqi',
        goal: '2 daqiqa',
        minimalGoal: '3 marta sekin nafas olish',
        whyNote: 'Shoshilinch paytda ham o‘zimga qaytish',
        category: HabitCategory.mind,
      ),
      StarterHabitSpec(
        name: 'Kundalik yozish',
        goal: '3 jumla',
        minimalGoal: 'Bitta jumla yozish',
        whyNote: 'Fikrlarimni tushunib, kunni yengil yakunlash',
        category: HabitCategory.mind,
      ),
      StarterHabitSpec(
        name: 'Telefonsiz sayr',
        goal: '10 daqiqa',
        minimalGoal: 'Tashqarida 2 daqiqa yurish',
        whyNote: 'Atrofimga e’tibor berish',
        category: HabitCategory.health,
      ),
    ],
    GrowthFocus.consistency => const [
      StarterHabitSpec(
        name: 'Bugungi ustuvor ishni yozish',
        goal: '1 muhim ish',
        minimalGoal: 'Bitta so‘z yozish',
        whyNote: 'Har kuni nimaga intilayotganimni bilish',
        category: HabitCategory.mind,
      ),
      StarterHabitSpec(
        name: '5 daqiqa harakat',
        goal: '5 daqiqa',
        minimalGoal: '30 soniya harakat',
        whyNote: 'Muntazamlikni kichik qadamdan qurish',
        category: HabitCategory.health,
      ),
      StarterHabitSpec(
        name: '2 sahifa o‘qish',
        goal: '2 sahifa',
        minimalGoal: 'Bitta paragraf',
        whyNote: 'Har kuni ozgina o‘sish',
        category: HabitCategory.study,
      ),
    ],
  };
}

GrowthFocus growthFocusFromId(String? id) {
  return GrowthFocus.values.firstWhere(
    (focus) => focus.name == id,
    orElse: () => GrowthFocus.consistency,
  );
}
