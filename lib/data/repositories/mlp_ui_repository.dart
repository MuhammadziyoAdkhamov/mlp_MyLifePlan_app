import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    implements MLPAuthRepository, MLPPreferencesRepository {
  MLPLocalUiRepository(this._prefs);
  static const storageKey = 'mlp_ui_prototype_v1';
  final SharedPreferences _prefs;
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
    'assessments': <dynamic>[],
    'favorites': <String>[],
    'cosmetic': 'default',
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
        for (final key in ['chat', 'schedules', 'assessments', 'favorites']) {
          if (merged[key] is! List) {
            throw const FormatException('UI ro‘yxati noto‘g‘ri.');
          }
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
      try {
        if (!await _prefs.setString(storageKey, jsonEncode(draft))) {
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
