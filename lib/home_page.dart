import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/main_view.dart';
import 'package:expensesappflutter/models/user_model.dart';
import 'package:expensesappflutter/pages/charts/monthly_budget_chart.dart';
import 'package:expensesappflutter/pages/prediction_page.dart';
import 'package:expensesappflutter/pages/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double expenses = 0.00;
  String name = '';
  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data including expenses
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final userData = userDoc.data();
      final userProfile = UserProfile.fromFirestore(userData!);
      setState(() {
        name = userProfile.name;
      });

      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .get();

      final expensesList = expensesSnapshot.docs
          .map((doc) => {
                'amount': (doc.data()['amount'] as num).toDouble(),
                'category': doc.data()['category'],
                'date': (doc.data()['date'] as Timestamp).toDate(),
                'isIncome': false
              })
          .toList();

      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final today = DateTime(now.year, now.month, now.day);

      // Calculate total expenses for the current year up to today
      expenses = expensesList.fold(0, (prev, element) {
        final transactionDate = element['date'] as DateTime;
        return (transactionDate.isAfter(startOfYear) &&
                transactionDate.isBefore(today.add(const Duration(days: 1))))
            ? prev + element['amount']
            : prev;
      });

      // Filter transactions for today and yesterday
      final filteredTransactions = expensesList.where((transaction) {
        final date = transaction['date'] as DateTime;
        return (date.isAfter(today.subtract(const Duration(days: 1))) &&
            date.isBefore(today.add(const Duration(days: 1))));
      }).toList();

      setState(() {
        transactions = filteredTransactions
          ..sort((a, b) => b['date'].compareTo(a['date']));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconForCategory(String category, bool isIncome) {
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
      case 'Gifts':
        return Icons.redeem_rounded;
      case 'Subscriptions':
        return Icons.subscriptions_rounded;
      case 'Insurance':
        return Icons.money_rounded;
      case 'Pets':
        return Icons.pets_rounded;
      case 'Childcare':
        return Icons.child_care_rounded;
      case 'Savings':
        return Icons.savings_rounded;
      case 'Miscellaneous':
        return Icons.category_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Total Expenses
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.mediumAccent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),

                  // Display total expenses for the current year (scheduled not included)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '€ ${NumberFormatter.formatAmount(expenses)}',
                        style: const TextStyle(
                            fontSize: 24.0,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.mediumAccent,
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PredictionPage(userId: widget.userId),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Expense Prediction',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Tap to see the forecast for next month',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.trending_up,
                          color: AppColors.primaryText, 
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.mediumAccent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 110,
                          child: MonthlyBudgetChart(userId: widget.userId),
                        )
                      ]),
                ),
                const SizedBox(height: 20.0),

                // Section 2: Expense
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expenses',
                      style: TextStyle(
                          fontSize: 16.0,
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionsPage(userId: widget.userId),
                          ),
                        ).then((value) {
                          if (value == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainView(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          }
                        });
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // Section 3: List of Expenses
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text('No Recent Expenses',
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w400)),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final icon = _getIconForCategory(
                                transaction['category'], false);
                            const color = AppColors.errorRed;
                            final transactionDate =
                                transaction['date'] as DateTime;
                            final now = DateTime.now();
                            final todayStart =
                                DateTime(now.year, now.month, now.day);
                            final yesterdayStart =
                                todayStart.subtract(const Duration(days: 1));

                            // Display expenses as of yesterday or previous day
                            String dateString;
                            if (transactionDate.isAfter(todayStart)) {
                              dateString =
                                  DateFormat('h:mm a').format(transactionDate);
                            } else if (transactionDate
                                .isAfter(yesterdayStart)) {
                              dateString = 'Yesterday';
                            } else {
                              dateString =
                                  DateFormat('MMM d').format(transactionDate);
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.lightAccent,
                                child:
                                    Icon(icon, color: AppColors.mediumAccent),
                              ),
                              title: Text(transaction['category'],
                                  style: const TextStyle(
                                      fontSize: 14.0,
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(dateString,
                                  style: const TextStyle(
                                      fontSize: 12.0,
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w400)),
                              trailing: Text(
                                '€ ${NumberFormatter.formatAmount(transaction['amount'])}',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Custom loading animation
          if (_isLoading)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mediumAccent,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.lightAccent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
