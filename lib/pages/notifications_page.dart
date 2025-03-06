import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Expense> _todayExpenses = [];
  List<Expense> _incomingExpenses = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Fetch expense data from database with future dates
  Future<void> _fetchNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses')
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Expense> todayExpenses = [];
    List<Expense> incomingExpenses = [];

    for (var doc in snapshot.docs) {
      final expense = Expense.fromFirestore(doc.data());
      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);

      if (expenseDate.isAtSameMomentAs(today)) {
        // Check if createdAt is before today (date of expense)
        if (expense.createdAt.toDate().isBefore(today)) {
          todayExpenses.add(expense);
        }
      } else if (expenseDate.isAfter(today)) {
        incomingExpenses.add(expense);
      }
    }

    setState(() {
      _todayExpenses = todayExpenses;

      _incomingExpenses = incomingExpenses;
    });
  }

  // Returns the corresponding icon for a given expense category.
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Rent':
        return Icons.house_rounded;
      case 'Internet':
        return Icons.router_rounded;
      case 'Utilities':
        return Icons.dynamic_form_rounded;
      case 'Transportation':
        return Icons.directions_car_rounded;
      case 'Groceries':
        return Icons.local_grocery_store_rounded;
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Shopping':
        return Icons.shopping_cart_rounded;
      case 'Repairs':
        return Icons.build_rounded;
      case 'Healthcare':
        return Icons.local_hospital_rounded;
      case 'Debt Payments':
        return Icons.credit_card_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Gifts/Donations':
        return Icons.redeem_rounded;
      case 'Subscriptions':
        return Icons.subscriptions_rounded;
      case 'Insurance':
        return Icons.money_rounded;
      case 'Pets':
        return Icons.pets_rounded;
      case 'Childcare':
        return Icons.child_care_rounded;
      case 'Savings/Investments':
        return Icons.savings_rounded;
      case 'Miscellaneous':
        return Icons.category_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildExpenseTile(Expense expense) {
    final icon = _getIconForCategory(expense.category);
    final dateString = DateFormat('MMM d, yyyy').format(expense.date);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.lightAccent,
        child: Icon(icon, color: AppColors.mediumAccent),
      ),
      title: Text(
        expense.category,
        style: const TextStyle(
          fontSize: 14.0,
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        dateString,
        style: const TextStyle(
          fontSize: 12.0,
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w300,
        ),
      ),
      trailing: Text(
        '€ ${NumberFormatter.formatAmount(expense.amount)}',
        style: const TextStyle(
          fontSize: 14.0,
          color: AppColors.errorRed,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Expense> expenses) {
    return expenses.isEmpty
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16.0,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600),
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return _buildExpenseTile(expense);
                },
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _todayExpenses.isEmpty && _incomingExpenses.isEmpty
            ? const Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Today', _todayExpenses),
                    const SizedBox(height: 16),
                    _buildSection('Incoming Expenses', _incomingExpenses),
                  ],
                ),
              ),
      ),
    );
  }
}
