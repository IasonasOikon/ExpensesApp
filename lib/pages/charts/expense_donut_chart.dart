import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/common/number_format.dart';
import 'package:expensesappflutter/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseDonutChart extends StatefulWidget {
  final String userId;

  const ExpenseDonutChart({super.key, required this.userId});

  @override
  _ExpenseDonutChartState createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  late Future<List<Expense>> expensesFuture;

  @override
  void initState() {
    super.initState();
    expensesFuture = _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    final expenseCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses');

    final expenseSnapshot = await expenseCollection.get();

    if (expenseSnapshot.docs.isEmpty) {
      return [];
    }

    return expenseSnapshot.docs
        .map((doc) => Expense.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mediumAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        dropdownColor: AppColors.mediumAccent,
                        iconEnabledColor: AppColors.primaryText,
                        style: const TextStyle(color: AppColors.primaryText),
                        underline: Container(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMonth = newValue!;
                          });
                        },
                        items: [
                          'January',
                          'February',
                          'March',
                          'April',
                          'May',
                          'June',
                          'July',
                          'August',
                          'September',
                          'October',
                          'November',
                          'December'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: expensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.lightAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Data Available',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                return _buildChart(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Expense> expenses) {
    final chartData = _processDataForChart(expenses);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: chartData.isEmpty
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
          : SfCircularChart(
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.top,
                textStyle: TextStyle(color: AppColors.primaryText),
              ),
              series: <CircularSeries>[
                DoughnutSeries<ExpenseData, String>(
                  dataSource: chartData,
                  xValueMapper: (ExpenseData data, _) => data.category,
                  yValueMapper: (ExpenseData data, _) => data.amount,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  dataLabelMapper: (ExpenseData data, _) =>
                      '${data.percentage.toStringAsFixed(1)}%',
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (dynamic data, dynamic point, dynamic series,
                    int pointIndex, int seriesIndex) {
                  final expenseData = data as ExpenseData;
                  return Container(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      '€ ${NumberFormatter.formatAmount(expenseData.amount)}',
                      style: const TextStyle(color: AppColors.primaryText),
                    ),
                  );
                },
              ),
            ),
    );
  }

  List<ExpenseData> _processDataForChart(List<Expense> expenses) {
    final groupedData = <String, double>{};
    double totalAmount = 0.0;
    int selectedMonthIndex = DateFormat('MMMM').parse(selectedMonth).month;

    for (var expense in expenses) {
      if (expense.date.month == selectedMonthIndex &&
          expense.date.year == DateTime.now().year) {
        totalAmount += expense.amount;
        groupedData.update(expense.category, (value) => value + expense.amount,
            ifAbsent: () => expense.amount);
      }
    }

    return groupedData.entries.map((entry) {
      double percentage =
          totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0;
      return ExpenseData(entry.key, entry.value, percentage);
    }).toList();
  }
}

class ExpenseData {
  final String category;
  final double amount;
  final double percentage;

  ExpenseData(this.category, this.amount, this.percentage);
}
