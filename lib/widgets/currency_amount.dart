import 'package:material_ui/material_ui.dart';

import '../data/currency_preferences.dart';
import '../utils/money_formatter.dart';

class CurrencyAmount extends StatelessWidget {
  const CurrencyAmount({
    super.key,
    required this.amountInCents,
    this.style,
    this.prefix,
  });

  final int amountInCents;
  final TextStyle? style;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CurrencyPreferences.instance.current,
      builder: (context, currency, child) {
        final amountText = formatCurrency(amountInCents, currency);

        return Text(
          prefix == null ? amountText : '$prefix $amountText',
          style: style,
        );
      },
    );
  }
}
