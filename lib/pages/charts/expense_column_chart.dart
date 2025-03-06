import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseColumnChart extends StatefulWidget {
  final String userId;

  const ExpenseColumnChart({super.key, required this.userId});

  @override
  _ExpenseColumnChartState createState() => _ExpenseColumnChartState();
}

class _ExpenseColumnChartState extends State<ExpenseColumnChart> {
  String selectedPeriod = 'Daily';
  String selectedMonth = 'January';
  late Future<List<Expense>> expensesFuture;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateFormat('MMMM').format(DateTime.now());
    expensesFuture = _fetchExpenses();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: FutureBuilder<List<Expense>>(
        future: expensesFuture,
        builder: (context, snapshot) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                        ),
                      ),
                      if (selectedPeriod != 'Monthly')
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
                              style:
                                  const TextStyle(color: AppColors.primaryText),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPeriod = 'Daily';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPeriod == 'Daily'
                              ? AppColors.mediumAccent
                              : AppColors.darkBase,
                          side: BorderSide(
                            color: selectedPeriod == 'Daily'
                                ? AppColors.mediumAccent
                                : AppColors.mediumAccent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Daily',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPeriod = 'Weekly';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPeriod == 'Weekly'
                              ? AppColors.mediumAccent
                              : AppColors.darkBase,
                          side: BorderSide(
                            color: selectedPeriod == 'Weekly'
                                ? AppColors.mediumAccent
                                : AppColors.mediumAccent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Weekly',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPeriod = 'Monthly';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPeriod == 'Monthly'
                              ? AppColors.mediumAccent
                              : AppColors.darkBase,
                          side: BorderSide(
                            color: selectedPeriod == 'Monthly'
                                ? AppColors.mediumAccent
                                : AppColors.mediumAccent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Monthly',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildChart(snapshot),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart(AsyncSnapshot<List<Expense>> snapshot) {
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 400,
      child: SfCartesianChart(
        primaryXAxis: _getXAxis(),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(
            color: AppColors.primaryText,
          ),
          majorGridLines: MajorGridLines(color: AppColors.mediumAccent),
        ),
        series: <CartesianSeries>[
          ColumnSeries<ExpenseData, String>(
            name: 'Expenses',
            dataSource: _processDataForChart(snapshot.data!, selectedPeriod),
            xValueMapper: (ExpenseData data, _) => data.period,
            yValueMapper: (ExpenseData data, _) => data.amount,
            color: AppColors.lightAccent,
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: AppColors.mediumAccent,
          textStyle: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 12,
          ),
        ),
        plotAreaBorderColor: Colors.transparent,
        plotAreaBorderWidth: 0,
      ),
    );
  }

  CategoryAxis _getXAxis() {
    return const CategoryAxis(
      labelStyle: TextStyle(
        color: AppColors.primaryText,
      ),
      majorGridLines: MajorGridLines(color: AppColors.mediumAccent),
      labelPlacement: LabelPlacement.onTicks,
      interval: 1,
    );
  }

  List<ExpenseData> _processDataForChart(
      List<Expense> expenses, String period) {
    final Map<String, double> groupedData = {};

    int selectedMonthIndex = DateFormat('MMMM').parse(selectedMonth).month;

    switch (period) {
      case 'Daily':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        for (var i = 0; i < 7; i++) {
          final day =
              DateFormat('E').format(startOfWeek.add(Duration(days: i)));
          groupedData[day] = 0;
        }

        for (var expense in expenses) {
          if (expense.date.month == selectedMonthIndex &&
              expense.date.year == DateTime.now().year &&
              expense.date.isAfter(startOfWeek) &&
              expense.date.isBefore(startOfWeek.add(const Duration(days: 7)))) {
            final String day = DateFormat('E').format(expense.date);
            groupedData.update(day, (value) => value + expense.amount);
          }
        }
        break;

      case 'Weekly':
        final List<String> weekLabels = [];
        final now = DateTime.now();
        final firstDateOfMonth = DateTime(now.year, selectedMonthIndex, 1);
        final lastDateOfMonth = DateTime(now.year, selectedMonthIndex + 1, 0);

        for (int week = 0; week < 6; week++) {
          final startOfWeek = firstDateOfMonth.add(Duration(days: week * 7));
          if (startOfWeek.isAfter(lastDateOfMonth)) break;
          final endOfWeek =
              startOfWeek.add(const Duration(days: 6)).isBefore(lastDateOfMonth)
                  ? startOfWeek.add(const Duration(days: 6))
                  : lastDateOfMonth;

          final weekRange = '${startOfWeek.day}-${endOfWeek.day}';
          weekLabels.add(weekRange);
          groupedData[weekRange] = 0;
        }

        for (var expense in expenses) {
          if (expense.date.month == selectedMonthIndex &&
              expense.date.year == DateTime.now().year) {
            for (String weekRange in weekLabels) {
              final days = weekRange.split('-');
              int startDay = int.parse(days[0]);
              int endDay = int.parse(days[1]);
              if (expense.date.day >= startDay && expense.date.day <= endDay) {
                groupedData[weekRange] =
                    groupedData[weekRange]! + expense.amount;
                break;
              }
            }
          }
        }
        break;

      case 'Monthly':
        for (var expense in expenses) {
          if (expense.date.year == DateTime.now().year) {
            final String month = DateFormat('MMM').format(expense.date);
            groupedData.update(month, (value) => value + expense.amount,
                ifAbsent: () => expense.amount);
          }
        }
        break;

      default:
        break;
    }

    if (period == 'Weekly') {
      final sortedData = groupedData.entries.toList()
        ..sort((a, b) => _compareWeekRanges(a.key, b.key));
      return sortedData
          .map((entry) => ExpenseData(entry.key, entry.value))
          .toList();
    }

    return groupedData.entries
        .map((entry) => ExpenseData(entry.key, entry.value))
        .toList();
  }

  int _compareWeekRanges(String a, String b) {
    List<int> aDays = a.split('-').map(int.parse).toList();
    List<int> bDays = b.split('-').map(int.parse).toList();

    return aDays[0].compareTo(bDays[0]);
  }
}

class ExpenseData {
  final String period;
  final double amount;

  ExpenseData(this.period, this.amount);
}
