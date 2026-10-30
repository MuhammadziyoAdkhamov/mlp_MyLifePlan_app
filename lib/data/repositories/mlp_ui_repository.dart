import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mlp_schedule.dart';

class MLPProfile {
  const MLPProfile({
    required this.name,
    required this.phone,
    required this.gender,
    required this.guest,
  });
  final String name, phone, gender;
  final bool guest;
  bool get verified => false;
  factory MLPProfile.fromJson(Map<String, dynamic> json) => MLPProfile(
    name: json['name'] as String,
    phone: json['phone'] as String,
    gender: json['gender'] as String,
    guest: json['guest'] as bool,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'gender': gender,
    'guest': guest,
  };
}

class MLPUserPreferences {
  const MLPUserPreferences({
    this.minutes = 90,
    this.startMinute = 18 * 60,
    this.endMinute = 21 * 60,
    this.notifications = false,
    this.nickname = 'Ziyo',
    this.tone = 'Sodda va aniq',
    this.allowContext = false,
    this.muted = false,
    this.voice = 'Standart (demo)',
  });
  final int minutes, startMinute, endMinute;
  final bool notifications, allowContext, muted;
  final String nickname, tone, voice;
  factory MLPUserPreferences.fromJson(Map<String, dynamic> json) =>
      MLPUserPreferences(
        minutes: json['minutes'] as int? ?? 90,
        startMinute: json['startMinute'] as int? ?? 1080,
        endMinute: json['endMinute'] as int? ?? 1260,
        notifications: json['notifications'] as bool? ?? false,
        nickname: json['nickname'] as String? ?? 'Ziyo',
        tone: json['tone'] as String? ?? 'Sodda va aniq',
        allowContext: json['allowContext'] as bool? ?? false,
        muted: json['muted'] as bool? ?? false,
        voice: json['voice'] as String? ?? 'Standart (demo)',
      );
  Map<String, dynamic> toJson() => {
    'minutes': minutes,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'notifications': notifications,
    'nickname': nickname,
    'tone': tone,
    'allowContext': allowContext,
    'muted': muted,
    'voice': voice,
  };
}

abstract interface class MLPAuthRepository {
  MLPProfile? get profile;
  Future<void> enterGuest({String name = 'Foydalanuvchi'});
  Future<void> registerDemo({
    required String name,
    required String phone,
    required String gender,
  });
  Future<void> exitSession();
}

abstract interface class MLPPreferencesRepository {
  MLPUserPreferences get preferences;
  Future<void> savePreferences(MLPUserPreferences value);
}

/// Explicit local authentication adapter: no OTP, no Firebase user/token.
/// Supplementary UI state uses a new key; legacy and DemoStore keys are untouched.
class MLPLocalUiRepository extends ChangeNotifier
    implements
        MLPAuthRepository,
        MLPPreferencesRepository,
        MLPScheduleRepository {
  MLPLocalUiRepository(this._prefs);
  static const storageKey = 'mlp_ui_prototype_v1';
  final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;
  Map<String, dynamic> _state = _defaults();
  Future<void> _queue = Future.value();
  bool initialized = false;
  String? error;
  bool _corrupt = false;

  static Map<String, dynamic> _defaults() => {
    'version': 1,
    'profile': null,
    'onboarded': false,
    'preferences': const MLPUserPreferences().toJson(),
    'chat': <dynamic>[],
    'goalPlans': <String, dynamic>{},
    'schedules': <dynamic>[],
    'scheduleResults': <dynamic>[],
    'assessments': <dynamic>[],
    'favorites': <String>[],
    'cosmetic': 'default',
    'focusDraft': null,
    'claimedRewards': <String>[],
    'city': 'Toshkent',
    'soundIntent': <String, dynamic>{'category': 'Fokus', 'sleep': 0},
    'assistantHidden': false,
  };

  @override
  MLPProfile? get profile => _state['profile'] == null
      ? null
      : MLPProfile.fromJson(
          Map<String, dynamic>.from(_state['profile'] as Map),
        );
  bool get onboarded => _state['onboarded'] as bool;
  bool get requiresRecovery => _corrupt;
  @override
  MLPUserPreferences get preferences => MLPUserPreferences.fromJson(
    Map<String, dynamic>.from(_state['preferences'] as Map),
  );

  Future<void> init() async {
    if (initialized) return;
    final raw = _prefs.get(storageKey);
    if (raw != null) {
      try {
        if (raw is! String) {
          throw const FormatException('Noto‘g‘ri saqlov turi.');
        }
        if (raw.length > 2 * 1024 * 1024) {
          throw const FormatException('UI saqlov hajmi katta.');
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic> ||
            decoded['version'] != 1 ||
            decoded['onboarded'] is! bool ||
            decoded['preferences'] is! Map) {
          throw const FormatException('UI zaxira formati mos emas.');
        }
        final merged = {..._defaults(), ...decoded};
        final savedProfile = merged['profile'];
        if (savedProfile != null) {
          final profile = MLPProfile.fromJson(
            Map<String, dynamic>.from(savedProfile as Map),
          );
          _name(profile.name, 'Ism');
          if (!profile.guest &&
              !RegExp(r'^\+998\d{9}$').hasMatch(profile.phone)) {
            throw const FormatException('Telefon formati noto‘g‘ri.');
          }
        }
        if (merged['onboarded'] == true && savedProfile == null) {
          throw const FormatException('Profil yo‘q.');
        }
        for (final key in [
          'chat',
          'schedules',
          'scheduleResults',
          'assessments',
          'favorites',
        ]) {
          if (merged[key] is! List) {
            throw const FormatException('UI ro‘yxati noto‘g‘ri.');
          }
        }
        final savedSchedules = (merged['schedules'] as List)
            .map(
              (s) => MLPSchedule.fromJson(Map<String, dynamic>.from(s as Map)),
            )
            .toList();
        if (savedSchedules.map((s) => s.id).toSet().length !=
            savedSchedules.length) {
          throw const FormatException('Takroriy jadval ID.');
        }
        for (final entry in merged['scheduleResults'] as List) {
          MLPScheduleResult.fromJson(Map<String, dynamic>.from(entry as Map));
        }
        if (merged['goalPlans'] is! Map ||
            (merged['goalPlans'] as Map).values.any((value) => value is! Map)) {
          throw const FormatException('Rejalar formati noto‘g‘ri.');
        }
        _checkPreferences(
          MLPUserPreferences.fromJson(
            Map<String, dynamic>.from(merged['preferences'] as Map),
          ),
        );
        _checkFeatureState(merged);
        _state = merged;
      } catch (_) {
        _corrupt = true;
        error = 'UI tanlovlarini o‘qib bo‘lmadi. Asl yozuv o‘zgartirilmadi.';
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> _update(void Function(Map<String, dynamic>) change) {
    final operation = _queue.then((_) async {
      if (_corrupt) {
        throw StateError(
          'UI saqlovi buzilgan. Tiklash yoki tasdiqlangan tozalash kerak.',
        );
      }
      final draft = jsonDecode(jsonEncode(_state)) as Map<String, dynamic>;
      change(draft);
      _checkFeatureState(draft);
      final encoded = jsonEncode(draft);
      if (encoded.length > 2 * 1024 * 1024) {
        throw StateError(
          'Demo saqlovi to‘ldi. Eski jadval yoki qaydlarni kamaytiring. Mavjud ma’lumotlar saqlanadi.',
        );
      }
      try {
        if (!await _prefs.setString(storageKey, encoded)) {
          throw StateError('Saqlov yozuvni qabul qilmadi.');
        }
      } catch (_) {
        error = 'Tanlovlarni saqlab bo‘lmadi. Qayta urinib ko‘ring.';
        try {
          await _prefs.reload();
        } catch (_) {
          error =
              'Saqlov va uning keshini tiklab bo‘lmadi. Ilovani qayta oching.';
        }
        notifyListeners();
        rethrow;
      }
      _state = draft;
      error = null;
      notifyListeners();
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }

  static String _name(String value, String label, {int min = 2, int max = 60}) {
    final clean = value.trim();
    if (clean.length < min || clean.length > max) {
      throw ArgumentError('$label $min–$max belgidan iborat bo‘lsin.');
    }
    return clean;
  }

  static void _checkFeatureState(Map<String, dynamic> state) {
    for (final key in ['favorites', 'claimedRewards']) {
      final list = state[key] as List;
      if (list.any((v) => v is! String || v.length > 100) ||
          list.toSet().length != list.length) {
        throw const FormatException('Tanlovlar noto‘g‘ri.');
      }
    }
    if (!(state['claimedRewards'] as List).every(
          (v) => ['cyan', 'violet', 'amber'].contains(v),
        ) ||
        !['default', 'cyan', 'violet', 'amber'].contains(state['cosmetic'])) {
      throw const FormatException('Virtual bezak noto‘g‘ri.');
    }
    if (![
          'Toshkent',
          'Samarqand',
          'Buxoro',
          'Andijon',
        ].contains(state['city']) ||
        state['assistantHidden'] is! bool) {
      throw const FormatException('Shahar yoki yordamchi tanlovi noto‘g‘ri.');
    }
    final sound = state['soundIntent'] as Map;
    if (!['Fokus', 'Tabiat', 'Dam olish'].contains(sound['category']) ||
        ![0, 15, 30, 60].contains(sound['sleep'])) {
      throw const FormatException('Audio tanlovi noto‘g‘ri.');
    }
    final chat = state['chat'] as List;
    if (chat.length > 100) {
      throw const FormatException('Chat chegarasi oshgan.');
    }
    for (final value in chat) {
      final message = value as Map;
      if (!['user', 'assistant'].contains(message['role'])) {
        throw const FormatException('Chat roli noto‘g‘ri.');
      }
      _name(
        message['text'] as String,
        'Xabar',
        min: 1,
        max: message['role'] == 'user' ? 1000 : 4000,
      );
      DateTime.parse(message['at'] as String);
    }
    for (final value in state['assessments'] as List) {
      final a = value as Map;
      if (!['Flutter asoslari', 'Ingliz tili asoslari'].contains(a['quiz']) ||
          a['kind'] != 'predefined-test' ||
          a['total'] != 3 ||
          a['correct'] is! int ||
          (a['correct'] as int) < 0 ||
          (a['correct'] as int) > 3 ||
          (a['taskId'] != null && a['taskId'] is! String)) {
        throw const FormatException('Baholash noto‘g‘ri.');
      }
      DateTime.parse(a['at'] as String);
    }
    final focus = state['focusDraft'];
    if (focus != null) {
      final f = focus as Map;
      _name(f['id'] as String, 'Sessiya', min: 1, max: 100);
      if (f['duration'] is! int ||
          (f['duration'] as int) < 60 ||
          (f['duration'] as int) > 10800 ||
          f['elapsed'] is! int ||
          (f['elapsed'] as int) < 0 ||
          (f['elapsed'] as int) > f['duration'] ||
          f['breakSeconds'] is! int ||
          (f['breakSeconds'] as int) < 60 ||
          (f['breakSeconds'] as int) > 1800 ||
          f['break'] is! bool ||
          (f['taskId'] != null && f['taskId'] is! String)) {
        throw const FormatException('Fokus holati noto‘g‘ri.');
      }
    }
  }

  @override
  Future<void> enterGuest({String name = 'Foydalanuvchi'}) {
    final clean = _name(name, 'Ism');
    return _update((draft) {
      draft['profile'] = MLPProfile(
        name: clean,
        phone: '',
        gender: 'Ko‘rsatmaslik',
        guest: true,
      ).toJson();
      draft['onboarded'] = true;
    });
  }

  @override
  Future<void> registerDemo({
    required String name,
    required String phone,
    required String gender,
  }) {
    final clean = _name(name, 'Ism');
    final number = phone.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (!RegExp(r'^\+998\d{9}$').hasMatch(number)) {
      throw ArgumentError('+998 va 9 xonali raqam kiriting.');
    }
    if (!['O‘g‘il', 'Qiz', 'Ko‘rsatmaslik'].contains(gender)) {
      throw ArgumentError('Jins tanlovi noto‘g‘ri.');
    }
    return _update((draft) {
      draft['profile'] = MLPProfile(
        name: clean,
        phone: number,
        gender: gender,
        guest: false,
      ).toJson();
      draft['onboarded'] = false;
    });
  }

  @override
  Future<void> savePreferences(MLPUserPreferences value) {
    _checkPreferences(value);
    return _update((draft) {
      draft['preferences'] = value.toJson();
    });
  }

  static void _checkPreferences(MLPUserPreferences value) {
    if (value.minutes < 5 || value.minutes > 720) {
      throw ArgumentError('Kunlik vaqt 5–720 daqiqa orasida bo‘lsin.');
    }
    if (value.startMinute < 0 ||
        value.endMinute >= 1440 ||
        value.startMinute >= value.endMinute) {
      throw ArgumentError('Boshlanish va tugash soatlari mos emas.');
    }
    _name(value.nickname, 'Ustoz nomi', min: 1, max: 30);
    if (![
      'Standart (demo)',
      'Sokin (demo)',
      'Ravon (demo)',
    ].contains(value.voice)) {
      throw ArgumentError('Ovoz tanlovi noto‘g‘ri.');
    }
    if (![
      'Sodda va aniq',
      'Qo‘llab-quvvatlovchi',
      'Batafsil',
    ].contains(value.tone)) {
      throw ArgumentError('Suhbat uslubi noto‘g‘ri.');
    }
  }

  Future<void> finishOnboarding() => _update((draft) {
    if (draft['profile'] == null) {
      throw StateError(
        'Avval mahalliy profil yarating yoki mehmon bo‘lib kiring.',
      );
    }
    draft['onboarded'] = true;
  });

  Future<void> saveWorkspaceIdentity(String name, int minutes) {
    final clean = _name(name, 'Ism');
    final settings = MLPUserPreferences.fromJson({
      ...preferences.toJson(),
      'minutes': minutes,
    });
    _checkPreferences(settings);
    return _update((draft) {
      if (draft['profile'] == null) {
        throw StateError('Mahalliy profil topilmadi.');
      }
      (draft['profile'] as Map)['name'] = clean;
      draft['preferences'] = settings.toJson();
    });
  }

  Map<String, dynamic>? goalPlan(String id) {
    final value = (_state['goalPlans'] as Map)[id];
    return value == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }

  Future<void> saveGoalPlan(String id, Map<String, dynamic> plan) {
    if (id.isEmpty) throw ArgumentError('Maqsad tanlanmagan.');
    final copy = jsonDecode(jsonEncode(plan));
    return _update((draft) => (draft['goalPlans'] as Map)[id] = copy);
  }

  Future<void> archiveGoal(String id, bool value) => _update((draft) {
    final plans = draft['goalPlans'] as Map;
    final plan = Map<String, dynamic>.from(plans[id] as Map? ?? {});
    plan['archived'] = value;
    plans[id] = plan;
  });

  Map<String, dynamic>? get focusDraft => _state['focusDraft'] == null
      ? null
      : Map<String, dynamic>.from(
          jsonDecode(jsonEncode(_state['focusDraft'])) as Map,
        );
  Future<void> saveFocusDraft(Map<String, dynamic>? value) =>
      _update((draft) => draft['focusDraft'] = value);
  List<Map<String, dynamic>> get messages => (_state['chat'] as List)
      .map((m) => Map<String, dynamic>.from(m as Map))
      .toList(growable: false);
  Future<void> saveConversationTurn(
    String question,
    String answer,
    DateTime at,
  ) {
    _name(question, 'Savol', min: 1, max: 1000);
    _name(answer, 'Javob', min: 1, max: 4000);
    return _update((draft) {
      final chat = draft['chat'] as List;
      chat.addAll([
        {'role': 'user', 'text': question, 'at': at.toIso8601String()},
        {'role': 'assistant', 'text': answer, 'at': at.toIso8601String()},
      ]);
      if (chat.length > 100) chat.removeRange(0, chat.length - 100);
    });
  }

  Future<void> clearConversation() =>
      _update((draft) => draft['chat'] = <dynamic>[]);
  List<Map<String, dynamic>> get assessments => (_state['assessments'] as List)
      .map((m) => Map<String, dynamic>.from(m as Map))
      .toList(growable: false);
  Future<void> saveAssessment({
    required String quiz,
    required int correct,
    required int total,
    required DateTime at,
    String? taskId,
  }) {
    if (total < 1 || correct < 0 || correct > total) {
      throw ArgumentError('Baholash natijasi noto‘g‘ri.');
    }
    return _update((draft) {
      final list = draft['assessments'] as List;
      list.removeWhere(
        (a) => (a as Map)['quiz'] == quiz && a['taskId'] == taskId,
      );
      list.add({
        'quiz': quiz,
        'taskId': taskId,
        'correct': correct,
        'total': total,
        'at': at.toIso8601String(),
        'kind': 'predefined-test',
      });
    });
  }

  List<String> get favorites => List<String>.from(_state['favorites'] as List);
  Future<void> toggleFavorite(String id) => _update((draft) {
    final list = draft['favorites'] as List;
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
  });
  String get cosmetic => _state['cosmetic'] as String;
  List<String> get claimedRewards =>
      List<String>.from(_state['claimedRewards'] as List);
  Future<void> useCosmetic(String id) => _update((draft) {
    draft['cosmetic'] = id;
    final list = draft['claimedRewards'] as List;
    if (!list.contains(id)) list.add(id);
  });
  String get city => _state['city'] as String;
  Future<void> selectCity(String value) =>
      _update((draft) => draft['city'] = value);
  Map<String, dynamic> get soundIntent =>
      Map<String, dynamic>.from(_state['soundIntent'] as Map);
  Future<void> saveSoundIntent(String category, int sleep) => _update(
    (draft) => draft['soundIntent'] = {'category': category, 'sleep': sleep},
  );
  bool get assistantHidden => _state['assistantHidden'] == true;
  Future<void> hideAssistant(bool value) =>
      _update((draft) => draft['assistantHidden'] = value);
  String exportUiState() => jsonEncode(_state);

  @override
  List<MLPSchedule> get schedules => List.unmodifiable(
    (_state['schedules'] as List).map(
      (s) => MLPSchedule.fromJson(Map<String, dynamic>.from(s as Map)),
    ),
  );
  @override
  List<MLPScheduleResult> get scheduleResults => List.unmodifiable(
    (_state['scheduleResults'] as List).map(
      (s) => MLPScheduleResult.fromJson(Map<String, dynamic>.from(s as Map)),
    ),
  );
  int _scheduleSerial = 0;
  String newScheduleId() =>
      'schedule-${DateTime.now().microsecondsSinceEpoch}-${_scheduleSerial++}';

  @override
  Future<void> saveSchedule(MLPSchedule value) => _update((draft) {
    final list = draft['schedules'] as List;
    final index = list.indexWhere((s) => (s as Map)['id'] == value.id);
    if (index < 0) {
      if (list.length >= 500) {
        throw StateError(
          'Demo chegarasi: 500 ta jadval. Eski jadvalni o‘chiring.',
        );
      }
      list.add(value.toJson());
    } else {
      list[index] = value.toJson();
    }
  });

  @override
  Future<void> deleteSchedule(String id) => _update((draft) {
    final list = draft['schedules'] as List;
    if (!list.any((s) => (s as Map)['id'] == id)) {
      throw StateError('Jadval topilmadi.');
    }
    list.removeWhere((s) => (s as Map)['id'] == id);
    (draft['scheduleResults'] as List).removeWhere(
      (r) => (r as Map)['scheduleId'] == id,
    );
  });

  @override
  Future<void> saveScheduleResult(MLPScheduleResult value) => _update((draft) {
    final data = (draft['schedules'] as List)
        .where((s) => (s as Map)['id'] == value.scheduleId)
        .firstOrNull;
    if (data == null ||
        !MLPSchedule.fromJson(
          Map<String, dynamic>.from(data as Map),
        ).occursOn(value.day)) {
      throw StateError('Ushbu sana uchun mashg‘ulot topilmadi.');
    }
    final schedule = MLPSchedule.fromJson(Map<String, dynamic>.from(data));
    if (value.reportedAt.isBefore(schedule.endOn(value.day))) {
      throw ArgumentError('Mashg‘ulot tugagach natijani qayd eting.');
    }
    final list = draft['scheduleResults'] as List;
    list.removeWhere(
      (r) =>
          (r as Map)['scheduleId'] == value.scheduleId &&
          r['day'] == mlpDayKey(value.day),
    );
    list.add(value.toJson());
  });

  @override
  Future<void> exitSession() => _update((draft) {
    draft['onboarded'] = false;
  });

  /// Called only after explicit destructive confirmation. DemoStore is separate.
  Future<void> resetUiData() {
    final operation = _queue.then((_) async {
      final next = _defaults();
      try {
        if (!await _prefs.setString(storageKey, jsonEncode(next))) {
          throw StateError('UI ma’lumotini tozalab bo‘lmadi.');
        }
      } catch (_) {
        try {
          await _prefs.reload();
        } catch (_) {
          /* Explicit UI error remains until recovery. */
        }
        error = 'UI tanlovlari tozalanmadi. Qayta urinib ko‘ring.';
        notifyListeners();
        rethrow;
      }
      _state = next;
      _corrupt = false;
      error = null;
      notifyListeners();
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }
}
