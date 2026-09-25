import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat("#,###", "fr_MG");

  static String format(double price) {
    return '${_formatter.format(price)} MGA';
  }
}
