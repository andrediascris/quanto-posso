import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  static final NumberFormat _input = NumberFormat('#,##0.00', 'pt_BR');

  static String format(double value) => _currency.format(value);

  static String formatForInput(double value) => _input.format(value);

  static double? tryParse(String value) {
    var normalized = value
        .trim()
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('R\$', '');
    if (normalized.isEmpty) return null;

    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');
    if (hasComma && hasDot) {
      if (normalized.lastIndexOf(',') > normalized.lastIndexOf('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (hasComma) {
      if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(normalized)) {
        normalized = normalized.replaceAll(',', '');
      } else {
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(normalized)) {
      normalized = normalized.replaceAll('.', '');
    }

    return double.tryParse(normalized);
  }
}
