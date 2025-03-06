import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseMeanVarianceChart extends StatefulWidget {
  final String userId;

  const ExpenseMeanVarianceChart({super.key, required this.userId});

  @override
  _ExpenseMeanVarianceChart createState() => _ExpenseMeanVarianceChart();
}

class _ExpenseMeanVarianceChart extends State<ExpenseMeanVarianceChart> {
  late Future<Map<String, CategoryStats>> statsFuture;
  double maxVariance = 0.0; // Track max variance for scaling

  @override
  void initState() {
    super.initState();
    statsFuture = _fetchExpensesAndCalculateStats();
  }

  Future<Map<String, CategoryStats>> _fetchExpensesAndCalculateStats() async {
    final expenseCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses');

    final expenseSnapshot = await expenseCollection.get();

    if (expenseSnapshot.docs.isEmpty) {
      return {};
    }

    List<Expense> expenses = expenseSnapshot.docs
        .map((doc) => Expense.fromFirestore(doc.data()))
        .toList();

    return _calculateStats(expenses);
  }

  Map<String, CategoryStats> _calculateStats(List<Expense> expenses) {
    Map<String, List<double>> categoryExpenses = {};

    for (var expense in expenses) {
      String category = expense.category;
      if (!categoryExpenses.containsKey(category)) {
        categoryExpenses[category] = [];
      }
      categoryExpenses[category]!.add(expense.amount);
    }

    Map<String, CategoryStats> categoryStats = {};

    double maxVarianceFound = 0.0;

    categoryExpenses.forEach((category, amounts) {
      double mean = amounts.reduce((a, b) => a + b) / amounts.length;
      double variance = amounts
              .map((amount) => (amount - mean) * (amount - mean))
              .reduce((a, b) => a + b) /
          amounts.length;

      categoryStats[category] = CategoryStats(category, mean, variance);

      // Track max variance
      if (variance > maxVarianceFound) {
        maxVarianceFound = variance;
      }
    });

    maxVariance = maxVarianceFound; // Store max variance for scaling
    return categoryStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: FutureBuilder<Map<String, CategoryStats>>(
        future: statsFuture,
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
    );
  }

  Widget _buildChart(Map<String, CategoryStats> stats) {
    List<CategoryStats> chartData = stats.values.toList();

    return Column(
      children: [
        // Title Above Chart (✅ Fix: Keep only ONE title)
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            'Mean & Variance Analysis of Expenses',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Scrollable Chart Display
        SizedBox(
          height: 300,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enables horizontal scrolling
            child: SizedBox(
              width: chartData.length * 80, // Adjust width dynamically
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                  labelStyle: TextStyle(color: AppColors.primaryText),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(color: AppColors.primaryText),
                  title: const AxisTitle(
                    text: 'Amount (€)',
                    textStyle: TextStyle(color: AppColors.primaryText),
                  ),
                  initialVisibleMinimum: 0,
                  initialVisibleMaximum: maxVariance > 5000 ? maxVariance / 10 : maxVariance,
                ),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom, 
                  alignment: ChartAlignment.near, 
                  textStyle: TextStyle(color: AppColors.primaryText),
                ),

                series: <CartesianSeries>[
                  ColumnSeries<CategoryStats, String>(
                    dataSource: chartData,
                    xValueMapper: (CategoryStats data, _) => data.category,
                    yValueMapper: (CategoryStats data, _) => data.mean,
                    name: 'Mean (€)',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.yellow, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  LineSeries<CategoryStats, String>(
                    dataSource: chartData,
                    xValueMapper: (CategoryStats data, _) => data.category,
                    yValueMapper: (CategoryStats data, _) => data.variance > 5000 ? data.variance / 10 : data.variance, 
                    name: 'Variance (€²)',
                    markerSettings: const MarkerSettings(isVisible: true),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.yellow, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Table Display
        Expanded(
          flex: 3,
          child: _buildStatsTable(stats),
        ),
      ],
    );
  }

  Widget _buildStatsTable(Map<String, CategoryStats> stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(AppColors.mediumAccent),
          columns: const [
            DataColumn(
              label: Text(
                'Category',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Mean (€)',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Variance (€²)',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: stats.entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text(
                  entry.key,
                  style: const TextStyle(color: AppColors.primaryText),
                )),
                DataCell(Text(
                  entry.value.mean.toStringAsFixed(2),
                  style: const TextStyle(color: AppColors.primaryText),
                )),
                DataCell(Text(
                  entry.value.variance.toStringAsFixed(2),
                  style: const TextStyle(color: AppColors.primaryText),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CategoryStats {
  final String category;
  final double mean;
  final double variance;

  CategoryStats(this.category, this.mean, this.variance);
}
