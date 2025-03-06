import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/pages/charts/expense_column_chart.dart';
import 'package:expensesappflutter/pages/charts/expense_donut_chart.dart';
import 'package:expensesappflutter/pages/charts/expense_mean_variance_chart.dart';
import 'package:flutter/material.dart';

class OverviewPage extends StatefulWidget {
  final String userId;

  const OverviewPage({super.key, required this.userId});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Display expense chart
                    SizedBox(
                      height: 520,
                      child: ExpenseColumnChart(userId: widget.userId),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 450,
                      child: ExpenseDonutChart(userId: widget.userId),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 800,
                      child: ExpenseMeanVarianceChart(userId: widget.userId)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
