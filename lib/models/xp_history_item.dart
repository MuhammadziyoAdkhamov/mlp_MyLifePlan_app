class XPHistoryItem {
  const XPHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.createdAt,
    this.habitId,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime createdAt;
  final String? habitId;

  XPHistoryItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? amount,
    DateTime? createdAt,
    String? habitId,
  }) {
    return XPHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      habitId: habitId ?? this.habitId,
    );
  }

  factory XPHistoryItem.fromJson(Map<String, dynamic> json) {
    return XPHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: json['amount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      habitId: json['habitId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'habitId': habitId,
    };
  }
}
