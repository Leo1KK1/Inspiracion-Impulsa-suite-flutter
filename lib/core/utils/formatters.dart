import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final _currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final _compactCurrency = NumberFormat.compactCurrency(
    locale: 'es_MX',
    symbol: r'$',
  );
  static final _date = DateFormat('dd MMM yyyy', 'es_MX');

  static String currency(num value) => _currency.format(value);
  static String compactCurrency(num value) => _compactCurrency.format(value);
  static String date(DateTime value) => _date.format(value);
}
