class AppBadge {
  const AppBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.requiredValue,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final int iconCodePoint;
  final int requiredValue;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  AppBadge copyWith({
    String? id,
    String? title,
    String? description,
    int? iconCodePoint,
    int? requiredValue,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return AppBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      requiredValue: requiredValue ?? this.requiredValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  factory AppBadge.fromJson(Map<String, dynamic> json) {
    return AppBadge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe838,
      requiredValue: json['requiredValue'] as int? ?? 1,
      unlockedAt: json['unlockedAt'] == null ? null : DateTime.parse(json['unlockedAt'] as String),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'requiredValue': requiredValue,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }
}
