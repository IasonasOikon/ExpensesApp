import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/models/category_model.dart';
import 'package:expensesappflutter/models/expense_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UpdateExpensePage extends StatefulWidget {
  final String userId;
  final String expenseCode;

  const UpdateExpensePage(
      {super.key, required this.userId, required this.expenseCode});

  @override
  State<UpdateExpensePage> createState() => _UpdateExpensePageState();
}

class _UpdateExpensePageState extends State<UpdateExpensePage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  String _selectedCategory = 'Rent';
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _customCategories = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Rent', 'icon': Icons.house_rounded},
    {'name': 'Internet', 'icon': Icons.router_rounded},
    {'name': 'Utilities', 'icon': Icons.dynamic_form_rounded},
    {'name': 'Transportation', 'icon': Icons.directions_car_rounded},
    {'name': 'Groceries', 'icon': Icons.local_grocery_store_rounded},
    {'name': 'Food', 'icon': Icons.fastfood_rounded},
    {'name': 'Shopping', 'icon': Icons.shopping_cart_rounded},
    {'name': 'Repairs', 'icon': Icons.build_rounded},
    {'name': 'Healthcare', 'icon': Icons.local_hospital_rounded},
    {'name': 'Debt Payments', 'icon': Icons.credit_card_rounded},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Travel', 'icon': Icons.flight_rounded},
    {'name': 'Gifts', 'icon': Icons.redeem_rounded},
    {'name': 'Subscriptions', 'icon': Icons.subscriptions_rounded},
    {'name': 'Insurance', 'icon': Icons.money_rounded},
    {'name': 'Pets', 'icon': Icons.pets_rounded},
    {'name': 'Childcare', 'icon': Icons.child_care_rounded},
    {'name': 'Savings/Investments', 'icon': Icons.savings_rounded},
    {'name': 'Miscellaneous', 'icon': Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(_onAmountFocusChange);
    _fetchExpenseData();
    _loadCategoriesFromDatabase();
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAmountFocusChange() {
    if (!_amountFocusNode.hasFocus) {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      _amountController.text = NumberFormatter.formatAmount(amount);
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    }
  }

  Future<void> _loadCategoriesFromDatabase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('categories')
        .get();

    setState(() {
      _customCategories.clear();
      for (var doc in snapshot.docs) {
        // Category instance from the document data
        final category = Category.fromMap(doc.data());

        _customCategories.add({
          'name': category.catName, // Using the catName property from Category
          'icon': Icons.widgets, // Fixed icon for custom categories
        });
      }
    });
  }

  Future<void> _fetchExpenseData() async {
    try {
      DocumentSnapshot expenseDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(widget.expenseCode)
          .get();

      if (expenseDoc.exists) {
        final expenseData = expenseDoc.data() as Map<String, dynamic>?;

        if (expenseData != null) {
          setState(() {
            _amountController.text = NumberFormatter.formatAmount(
              (expenseData['amount'] as num?)?.toDouble() ?? 0.0,
            );
            _descriptionController.text =
                expenseData['description'] as String? ?? '';
            _selectedCategory = expenseData['category'] as String? ?? 'Rent';
            _selectedDate =
                (expenseData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expense data found for this entry')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense data: $e')),
      );
    }
  }

  void _updateExpense() async {
    final rawAmount = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(rawAmount) ?? 0.0;
    final description = _descriptionController.text;

    if (amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
            child: Text('Please enter valid details'),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.0),
        ),
      );
      return;
    }

    final updatedExpense = Expense(
      amount: double.parse(amount.toStringAsFixed(2)),
      description: description,
      category: _selectedCategory,
      date: _selectedDate,
      createdAt: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(widget.expenseCode)
          .update(updatedExpense.toFirestore());

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update expense: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: AppBar(
        title: const Text(
          'Update Expense',
          style: TextStyle(color: AppColors.primaryText),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBase,
        iconTheme: const IconThemeData(
          color: AppColors.primaryText,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Input
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.mediumAccent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 24.0,
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: const TextStyle(
                            fontSize: 24.0,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'EUR',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Description Input
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w300,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter description',
                      hintStyle: const TextStyle(
                        fontSize: 14.0,
                        color: AppColors.secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: AppColors.mediumAccent,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12.0),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Date Picker
                  const Text(
                    'Date',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (selectedDate != null &&
                          selectedDate != _selectedDate) {
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.mediumAccent),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.yMMMd().format(_selectedDate),
                            style: const TextStyle(
                                fontSize: 14.0, color: AppColors.primaryText),
                          ),
                          const Icon(Icons.calendar_today,
                              color: AppColors.primaryText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Category Selection
                  const Text(
                    'Category',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 100.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add custom categories
                        ..._customCategories.map((customCategory) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = customCategory['name'];
                                });
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30.0,
                                    backgroundColor: _selectedCategory ==
                                            customCategory['name']
                                        ? AppColors.lightAccent
                                        : AppColors.mediumAccent,
                                    child: Icon(
                                      customCategory['icon'],
                                      color: _selectedCategory ==
                                              customCategory['name']
                                          ? AppColors.mediumAccent
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 5.0),
                                  Text(
                                    customCategory['name'],
                                    style: TextStyle(
                                      color: _selectedCategory ==
                                              customCategory['name']
                                          ? AppColors.lightAccent
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // Default Categories
                        ..._categories.map((category) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category['name'];
                                });
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30.0,
                                    backgroundColor:
                                        _selectedCategory == category['name']
                                            ? AppColors.lightAccent
                                            : AppColors.mediumAccent,
                                    child: Icon(
                                      category['icon'],
                                      color:
                                          _selectedCategory == category['name']
                                              ? AppColors.mediumAccent
                                              : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 5.0),
                                  Text(
                                    category['name'],
                                    style: TextStyle(
                                      color:
                                          _selectedCategory == category['name']
                                              ? AppColors.lightAccent
                                              : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    color: AppColors.darkBase,
                    child: SizedBox(
                      height: 50.0,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'Update Expense',
                          style: TextStyle(
                              fontSize: 16.0,
                              color: AppColors.darkBase,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
