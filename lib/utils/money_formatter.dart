import '../models/app_currency.dart';

String formatCurrency(int amountInCents, AppCurrency currency) {
  final sign = amountInCents < 0 ? '-' : '';
  final absoluteAmount = amountInCents.abs();
  final wholeAmount = absoluteAmount ~/ 100;
  final cents = (absoluteAmount % 100).toString().padLeft(2, '0');

  final amountWithCommas = wholeAmount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  return '$sign${currency.symbol} $amountWithCommas.$cents';
}
