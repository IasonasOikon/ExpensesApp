import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/pages/expense_pages/update_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsPage extends StatefulWidget {
  final String userId;

  const TransactionsPage({super.key, required this.userId});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Fetch transactions from Firestore and updates the state.
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .get();

      final now = DateTime.now();

      final expensesList = expensesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'amount': (doc.data()['amount'] as num).toDouble(),
                'category': doc.data()['category'],
                'date': (doc.data()['date'] as Timestamp).toDate(),
              })
          .where((expense) =>
              (expense['date'] as DateTime).isBefore(now) ||
              (expense['date'] as DateTime).isAtSameMomentAs(now))
          .toList();

      setState(() {
        transactions = expensesList
          ..sort((a, b) => b['date'].compareTo(a['date']));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigates to the UpdateExpensePage for editing a transaction.
  void _onTransactionTap(Map<String, dynamic> transaction) async {
    bool? isUpdated;

    isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateExpensePage(
          userId: widget.userId,
          expenseCode: transaction['id'],
        ),
      ),
    );

    if (isUpdated == true) {
      _fetchTransactions();
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(transactionId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: $e')),
        );
      }
    }
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
      case 'Food & Drinks':
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
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          'Expenses',
          style: TextStyle(color: AppColors.primaryText),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBase,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: AppColors.primaryText,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isLoading
                  ? Center(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.lightAccent),
                          ),
                        ),
                      ),
                    )
                  : transactions.isEmpty
                      ? const Center(
                          child: Text('No Expenses',
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w300)),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final icon =
                                _getIconForCategory(transaction['category']);

                            final transactionDate =
                                transaction['date'] as DateTime;
                            final now = DateTime.now();
                            final todayStart =
                                DateTime(now.year, now.month, now.day);
                            final yesterdayStart =
                                todayStart.subtract(const Duration(days: 1));

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

                            // Slide or swipe to the left to show delete option.
                            return Slidable(
                              key: Key(
                                  transaction['category'] + index.toString()),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.2,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) async {
                                      final transactionId = transaction['id'];

                                      await _deleteTransaction(transactionId);

                                      setState(() {
                                        transactions.removeAt(index);
                                      });
                                    },
                                    backgroundColor: AppColors.errorRed,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_rounded,
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () => _onTransactionTap(transaction),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.lightAccent,
                                    child: Icon(icon,
                                        color: AppColors.mediumAccent),
                                  ),
                                  title: Text(
                                    transaction['category'],
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
                                    '€ ${NumberFormatter.formatAmount(transaction['amount'])}',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: AppColors.errorRed,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
