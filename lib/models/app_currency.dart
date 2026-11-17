enum AppCurrency {
  myr(code: 'MYR', symbol: 'RM'),
  usd(code: 'USD', symbol: '\$'),
  sgd(code: 'SGD', symbol: 'S\$'),
  gbp(code: 'GBP', symbol: '£');

  const AppCurrency({
    required this.code,
    required this.symbol,
  });

  final String code;
  final String symbol;

  String get label => '$symbol ($code)';

  static AppCurrency fromCode(String? code) {
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => AppCurrency.myr,
    );
  }
}
