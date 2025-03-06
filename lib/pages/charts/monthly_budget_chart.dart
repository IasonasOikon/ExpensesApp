import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/models/expense_model.dart';
import 'package:expensesappflutter/models/user_model.dart';
import 'package:flutter/material.dart';

class MonthlyBudgetChart extends StatefulWidget {
  final String userId;

  const MonthlyBudgetChart({super.key, required this.userId});

  @override
  _MonthlyBudgetChartState createState() => _MonthlyBudgetChartState();
}

class _MonthlyBudgetChartState extends State<MonthlyBudgetChart> {
  late Future<List<Expense>> expensesFuture;
  late Future<UserProfile> userProfileFuture;

  @override
  void initState() {
    super.initState();
    expensesFuture = _fetchExpenses();
    userProfileFuture = _fetchUserProfile();
  }

  Future<List<Expense>> _fetchExpenses() async {
    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses')
        .get();

    return expenseSnapshot.docs
        .map((doc) => Expense.fromFirestore(doc.data()))
        .toList();
  }

  Future<UserProfile> _fetchUserProfile() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    return UserProfile.fromFirestore(userDoc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumAccent,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Monthly Budget Goal',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<UserProfile>(
              future: userProfileFuture,
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center();
                }

                if (!userSnapshot.hasData) {
                  return const Center(
                      child: Text(
                    'No Data Available',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ));
                }

                return FutureBuilder<List<Expense>>(
                  future: expensesFuture,
                  builder: (context, expenseSnapshot) {
                    if (expenseSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center();
                    }

                    if (!expenseSnapshot.hasData ||
                        expenseSnapshot.data!.isEmpty) {
                      return const Center(
                          child: Text(
                        'No Data Available',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ));
                    }

                    return _buildProgressChart(
                        userSnapshot.data!, expenseSnapshot.data!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(UserProfile userProfile, List<Expense> expenses) {
    int currentMonthIndex = DateTime.now().month;
    double totalExpenses = expenses
        .where((expense) =>
            expense.date.month == currentMonthIndex &&
            expense.date.year == DateTime.now().year)
        .fold(0.0, (sum, item) => sum + item.amount);

    double budgetGoal = userProfile.monthlyBudgetGoal;
    bool isOverBudget = totalExpenses > budgetGoal;

    // Determine the color based on whether expenses exceed the budget
    Color progressColor = totalExpenses > budgetGoal
        ? AppColors.errorRed // Color when over budget
        : AppColors.primaryText; // Default color when within budget

    return Padding(
      padding: const EdgeInsets.all(0),
      child: expenses.isEmpty && budgetGoal.isNaN
          ? const Center(
              child: Text(
                'No Data Available',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: AppColors.darkBase.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: budgetGoal > 0 ? totalExpenses / budgetGoal : 0,
                      backgroundColor: AppColors.darkBase.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${NumberFormatter.formatAmount(totalExpenses)}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'LIMIT EXCEEDED!',
                      style: TextStyle(
                        color: isOverBudget
                            ? AppColors.errorRed
                            : Colors.transparent,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '€${NumberFormatter.formatAmount(budgetGoal)}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
