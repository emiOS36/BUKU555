import 'package:material_ui/material_ui.dart';
import 'package:buku555/widgets/currency_amount.dart';

class ReusableCard extends StatelessWidget {
  final Widget icon;
  final String type;
  final int amount;

  const ReusableCard({
    super.key,
    required this.icon,
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 85),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: .circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.4),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          icon,
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                type,
                style: TextStyle(fontSize: 15, fontWeight: .w500),
              ),
              SizedBox(height: 1),
              CurrencyAmount(
                amountInCents: amount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
