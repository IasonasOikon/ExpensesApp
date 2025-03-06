import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final double amount;
  final String description;
  final String category;
  final DateTime date;

  Income({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
  });

  factory Income.fromFirestore(Map<String, dynamic> data) {
    return Income(
      amount: data['amount']?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date,
    };
  }
}
