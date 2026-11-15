import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formats amounts with the correct symbol and locale separators.
/// Never converts currencies — that is the server's job.
class CurrencyFormatter {
  static String format(double amount, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, currency);
  }

  static String symbol(String currency) =>
      AppConstants.currencySymbols[currency] ?? currency;

  static String formatCny(double amount) =>
      '¥${NumberFormat('#,##0.00').format(amount)}';
}
