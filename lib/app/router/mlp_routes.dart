import 'package:flutter/material.dart';

/// Complete required inventory. A declaration is not a completed screen.
enum MLPScreen {
  splash('/splash', 'MLP', 'B'),
  welcome('/welcome', 'Xush kelibsiz', 'B'),
  registration('/registration', 'Demo profil yaratish', 'B'),
  login('/login', 'Kirish', 'B'),
  preferences('/preferences', 'Mening tanlovlarim', 'B'),
  goalDiscovery('/goals/new', 'Maqsad tanlash', 'B'),
  goalClarification('/goals/clarify', 'Maqsadni aniqlashtirish', 'B'),
  diagnosis('/goals/diagnosis', 'Boshlang‘ich baholash', 'B'),
  roadmap('/goals/roadmap', 'Yo‘l xaritasini ko‘rish', 'B'),
  goalDetail('/goals/detail', 'Maqsad tafsilotlari', 'C'),
  today('/today', 'Bugun', 'C'),
  calendar('/calendar', 'Taqvim', 'C'),
  scheduleEditor('/calendar/edit', 'Mashg‘ulotni rejalash', 'C'),
  focus('/focus', 'Fokus markazi', 'C'),
  activeFocus('/focus/active', 'Diqqat vaqti', 'C'),
  focusSummary('/focus/summary', 'Fokus yakuni', 'C'),
  chat('/ustoz', 'USTOZ AI', 'D'),
  voice('/ustoz/voice', 'Ovozli suhbat ko‘rinishi', 'D'),
  aiPersonalization('/ustoz/preferences', 'Ustozni moslash', 'D'),
  verification('/verification', 'Natijani tekshirish', 'D'),
  passport('/passport', 'Ko‘nikmalar pasporti', 'D'),
  analytics('/progress', 'Rivojlanish', 'D'),
  rewards('/rewards', 'Yutuqlar', 'E'),
  weather('/weather', 'Ob-havo va reja', 'E'),
  soundspace('/soundspace', 'MLP Soundspace', 'E'),
  profile('/profile', 'Profil', 'E'),
  settings('/settings', 'Sozlamalar', 'E'),
  notifications('/notifications', 'Bildirishnomalar', 'E');

  const MLPScreen(this.path, this.title, this.phase);
  final String path, title, phase;

  static MLPScreen? parse(String? path) {
    if (path == null) return null;
    final uri = Uri.tryParse(path);
    return values.where((screen) => screen.path == uri?.path).firstOrNull;
  }
}

class MLPRouteArgs {
  const MLPRouteArgs({
    this.goalId,
    this.taskId,
    this.scheduleId,
    this.rewardId,
  });
  final String? goalId, taskId, scheduleId, rewardId;
}

abstract final class MLPNavigation {
  static Future<T?> open<T>(
    BuildContext context,
    MLPScreen screen, {
    MLPRouteArgs? args,
  }) => Navigator.of(context).pushNamed<T>(screen.path, arguments: args);
}
