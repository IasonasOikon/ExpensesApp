import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:expensesappflutter/models/user_model.dart';

class ExpensePredictionModel {
  final String userId;

  ExpensePredictionModel({required this.userId});

  // Fetch past monthly expenses from Firestore based on selected years
  /// Fetch past monthly expenses from Firestore based on selected years
  Future<Map<int, double>> fetchMonthlyExpenses(int yearsBack) async {
  final expenseCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('expenses');

  final expenseSnapshot = await expenseCollection.get();

  if (expenseSnapshot.docs.isEmpty) {
    return {};
  }

  DateTime now = DateTime.now();
  int minYear = now.year - yearsBack;

  //  Store total expenses per month
  Map<int, double> monthlyExpenses = {};

  for (var doc in expenseSnapshot.docs) {
    double amount = (doc.data()['amount'] as num).toDouble();
    DateTime date = (doc.data()['date'] as Timestamp).toDate();

    if (date.year >= minYear) {
      int monthKey = date.year * 12 + date.month; // Unique month key

      //  Ensure we sum up all expenses per month correctly
      monthlyExpenses.update(monthKey, (prev) => prev + amount, ifAbsent: () => amount);
    }
  }

  return monthlyExpenses;
}

  /// Fetch the user's monthly budget from Firestore
 Future<double> fetchUserBudget() async {
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (userDoc.exists && userDoc.data() != null) {
    final userProfile = UserProfile.fromFirestore(userDoc.data()!);
    return userProfile.monthlyBudgetGoal; 
  }
  return 0.0; // Default budget if not set
}
  /// Predict next month's expense based on user-selected years
  Future<Map<String, dynamic>> predictNextMonthExpense(int yearsBack, {int monthsForward = 1}) async {
  Map<int, double> monthlyExpenses = await fetchMonthlyExpenses(yearsBack);
  double userBudget = await fetchUserBudget();

  if (monthlyExpenses.length < 2) {
    double lastExpense = monthlyExpenses.isNotEmpty ? monthlyExpenses.values.last : 0.0;
    return {
      'prediction': lastExpense,
      'budget': userBudget,
      'overBudget': lastExpense > userBudget,
      'pastExpenses': monthlyExpenses,
      'trend': []
    };
  }

  List<int> xValues = monthlyExpenses.keys.toList();
  List<double> yValues = monthlyExpenses.values.toList();

  int n = xValues.length;
  double sumX = xValues.reduce((a, b) => a + b).toDouble();
  double sumY = yValues.reduce((a, b) => a + b);
  double sumXY = 0.0;
  double sumX2 = 0.0;

  for (int i = 0; i < n; i++) {
    sumXY += xValues[i] * yValues[i];
    sumX2 += pow(xValues[i], 2);
  }

  // Linear Regression to find trend (y = mx + b)
  double m = (n * sumXY - sumX * sumY) / (n * sumX2 - pow(sumX, 2));
  double b = (sumY - m * sumX) / n;

  // Predict expenses for the next `monthsForward` months
  List<MapEntry<int, double>> trend = [];
  DateTime now = DateTime.now();
  int nextMonth = (now.year * 12) + now.month + 1;
  
  for (int i = 0; i < monthsForward; i++) {
    int futureMonth = nextMonth + i;
    trend.add(MapEntry(futureMonth, m * futureMonth + b));
  }

  return {
    'prediction': m * nextMonth + b,
    'budget': userBudget,
    'overBudget': (m * nextMonth + b) > userBudget,
    'pastExpenses': monthlyExpenses,
    'trend': trend
  };
}

}