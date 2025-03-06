import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final Timestamp createdAt;

  Expense({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data) {
    return Expense(
      amount: data['amount']?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date,
      'createdAt': createdAt,
    };
  }
}
