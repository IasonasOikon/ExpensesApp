import 'package:intl/intl.dart';

class NumberFormatter {
  static String formatAmount(double amount) {
    final NumberFormat formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }
}
