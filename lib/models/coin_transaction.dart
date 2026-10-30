import 'package:equatable/equatable.dart';

class CoinTransaction extends Equatable {
  const CoinTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final int amount;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, amount, createdAt];

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
