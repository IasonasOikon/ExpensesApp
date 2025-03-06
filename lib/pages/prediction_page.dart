import 'dart:math';

import 'package:flutter/material.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:expensesappflutter/services/prediction_model.dart';

class PredictionPage extends StatefulWidget {
  final String userId;
  const PredictionPage({super.key, required this.userId});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  int selectedYearsBack = 2; // Default 2 years
  double? predictedExpense;
  double? userBudget;
  bool overBudget = false;
  bool _isLoading = true;
  Map<int, double> pastExpenses = {};
  List<MapEntry<int, double>> predictionLine = [];
  List<MapEntry<int, double>> budgetLine = [];
  List<MapEntry<int, double>> regressionTrend = [];

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    setState(() {
      _isLoading = true;
    });

    ExpensePredictionModel predictor = ExpensePredictionModel(userId: widget.userId);
    Map<String, dynamic> predictionData = await predictor.predictNextMonthExpense(selectedYearsBack, monthsForward: 6);

    setState(() {
      predictedExpense = predictionData['prediction'];
      userBudget = predictionData['budget'];
      overBudget = predictionData['overBudget'];
      pastExpenses = predictionData['pastExpenses'];

      // 🔹 Ensure last 6 months of actual expenses are shown in the first chart
      Map<int, double> lastSixMonths = {};
      DateTime now = DateTime.now();
      for (int i = 0; i < 6; i++) {
        int month = now.month - i;
        int year = now.year;
        if (month <= 0) {
          month += 12;
          year -= 1;    
        }
        int key = (year * 12) + month;
        lastSixMonths[key] = pastExpenses[key] ?? 0.0; // Use actual data if available, else 0
      }

      List<MapEntry<int, double>> lastSixMonthsList = lastSixMonths.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      pastExpenses = Map.fromEntries(lastSixMonthsList);

      // Past 6 months data
      predictionLine = pastExpenses.entries.map((e) => MapEntry(e.key, predictedExpense!)).toList();
      budgetLine = pastExpenses.entries.map((e) => MapEntry(e.key, userBudget!)).toList();

      // Linear regression trend for future months
      regressionTrend = predictionData['trend']; 

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: AppBar(
        backgroundColor: AppColors.darkBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Expense Prediction',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Predict Your Next Month’s Expenses',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Based on your past spending habits, this page provides an estimate of your expected expenses for the upcoming month. This can help you plan your budget more effectively.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: selectedYearsBack,
                dropdownColor: AppColors.mediumAccent,
                iconEnabledColor: AppColors.primaryText,
                style: const TextStyle(color: AppColors.primaryText),
                items: [1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                        value == 1 ? '1 Year'
                        : '$value Years'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYearsBack = newValue;
                      _fetchPrediction(); // Refresh prediction
                    });
                  }
                },
              ),
        
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (overBudget)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Your predicted expenses (€${predictedExpense!.toStringAsFixed(2)}) exceed your budget (€${userBudget!.toStringAsFixed(2)}). Consider adjusting your spending!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        const SizedBox(height: 20),
                          
                        Center(
                          child: Card(
                            color: AppColors.mediumAccent,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Predicted Expense for Next Month',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '€ ${predictedExpense!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SfCartesianChart(
                          title: const ChartTitle(
                            text: 'Expense Trend & Prediction',
                            textStyle: TextStyle(color: AppColors.primaryText),
                            alignment: ChartAlignment.near,
                          ),
                          primaryXAxis: const CategoryAxis(
                            labelStyle: TextStyle(color: AppColors.primaryText),
                            title: AxisTitle(
                              text: 'Month',
                              textStyle: TextStyle(color: AppColors.primaryText),
                            ),
                            interval: 1,
                          ),
                          primaryYAxis: const NumericAxis(
                            labelStyle: TextStyle(color: AppColors.primaryText),
                            title: AxisTitle(
                              text: 'Total Expense (€)',
                              textStyle: TextStyle(color: AppColors.primaryText),
                            ),
                          ),
                          legend: const Legend(
                            alignment: ChartAlignment.near,
                            isVisible: true,
                            position: LegendPosition.bottom,
                            textStyle: TextStyle(color: AppColors.primaryText),
                          ),
                          series: <CartesianSeries<MapEntry<int, double>, String>>[
                            LineSeries<MapEntry<int, double>, String>(
                              dataSource: pastExpenses.entries.toList()
                                            ..sort((a, b) => b.key.compareTo(a.key)),
                              xValueMapper: (entry, _) => _formatMonthYear(entry.key),
                              yValueMapper: (entry, _) => entry.value,
                              name: 'Actual Expenses',
                              color: Colors.blue,
                              width: 3,
                              markerSettings: const MarkerSettings(isVisible: true),
                              dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                            ),
                                
                            LineSeries<MapEntry<int, double>, String>(
                              dataSource: predictionLine,
                              xValueMapper: (entry, _) => _formatMonthYear(entry.key),
                              yValueMapper: (entry, _) => entry.value,
                              name: 'Predicted Expense',
                              color: Colors.yellow,
                              width: 3,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                                
                            if (userBudget! > 0)
                              LineSeries<MapEntry<int, double>, String>(
                                dataSource: budgetLine,
                                xValueMapper: (entry, _) => _formatMonthYear(entry.key),
                                yValueMapper: (entry, _) => entry.value,
                                name: 'Budget Limit',
                                color: Colors.red,
                                dashArray: const [5, 5],
                                width: 2,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Linear Regression Chart',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 1,
                        ),
                        const Text(
                          'This chart represents the linear regression trend of your past expenses, helping to visualize patterns in your spending behavior.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14
                          ),
                        ),
                        const SizedBox(height: 10),
                        SfCartesianChart(
                          title: const ChartTitle(
                            text: 'Future Expense Trend',
                            textStyle: TextStyle(color: AppColors.primaryText),
                            alignment: ChartAlignment.near
                          ),
                          primaryXAxis: const CategoryAxis(
                            labelStyle: TextStyle(color: AppColors.primaryText),
                          ),
                          primaryYAxis: const NumericAxis(
                            labelStyle: TextStyle(color: AppColors.primaryText),
                          ),
                          series: <CartesianSeries<MapEntry<int, double>, String>>[
                            LineSeries<MapEntry<int, double>, String>(
                              dataSource: regressionTrend,
                              xValueMapper:(entry, _) => _formatFutureMonth(entry.key),
                              yValueMapper: (entry, _) => double.parse(entry.value.toStringAsFixed(2)),
                              name: 'Predicted Trend',
                              color: Colors.orange,
                              width: 3,
                              dataLabelSettings: const DataLabelSettings(
                                labelAlignment: ChartDataLabelAlignment.auto,
                                overflowMode: OverflowMode.shift,
                                isVisible: true, 
                                textStyle: TextStyle(
                                  fontSize: 8,
                                    color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(int key) {
    int year = key ~/ 12;
    int month = key % 12;

    if (month == 0) {
      month = 12;
      year -= 1;
    }

    return '${month.toString().padLeft(2, '0')}/${year % 100}';
  }

  String _formatFutureMonth(int key) {
  int year = key ~/ 12;
  int month = key % 12;
  if (month == 0) {
    month = 12;
    year -= 1;
  }
  return '${month.toString().padLeft(2, '0')}/${year % 100}';
  } 

}
