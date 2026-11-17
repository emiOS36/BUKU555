import 'package:flutter/material.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/app_currency.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnable = true;

  Future<void> _chooseCurrency() async {
    final transactions = await TransactionDatabase.instance.getAll();

    if (!mounted) return;

    // Existing transactions are assumed to use the current currency.
    // Changing it here would relabel their amounts without converting them.
    if (transactions.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Currency can’t be changed'),
          content: const Text(
            'This ledger already has transactions in its current currency.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final currentCurrency = CurrencyPreferences.instance.current.value;

    final selectedCurrency = await showDialog<AppCurrency>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose currency'),
        children: [
          for (final currency in AppCurrency.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, currency),
              child: Row(
                children: [
                  Expanded(child: Text(currency.label)),
                  if (currency == currentCurrency)
                    const Icon(Icons.check, color: Colors.teal),
                ],
              ),
            ),
        ],
      ),
    );

    if (!mounted || selectedCurrency == null) return;

    await CurrencyPreferences.instance.save(selectedCurrency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 25, fontWeight: .bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SettingsSection(
              title: 'Account & App',
              rows: [
                ValueListenableBuilder<AppCurrency>(
                  valueListenable: CurrencyPreferences.instance.current,
                  builder: (context, currency, child) {
                    return _SettingsRow(
                      icon: Icons.currency_exchange,
                      title: 'Currency',
                      value: currency.label,
                      onTap: _chooseCurrency,
                    );
                  },
                ),
                _SettingsRow(
                  icon: Icons.brightness_6_outlined,
                  title: 'App Theme',
                  value: 'System',
                ),
                _SettingsRow(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  value: 'English',
                ),
                _SettingsRow(
                  icon: Icons.notifications_none,
                  title: 'Notification',
                  showChevron: false,
                  trailing: Switch(
                    value: _notificationEnable,
                    activeTrackColor: Colors.teal,
                    onChanged: ((value) {
                      setState(() {
                        _notificationEnable = value;
                      });
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'Data & Backup',
              rows: [
                _SettingsRow(
                  icon: Icons.file_upload_outlined,
                  title: 'Export Data',
                ),
                _SettingsRow(
                  icon: Icons.file_download_outlined,
                  title: 'Import Data',
                ),
                _SettingsRow(
                  icon: Icons.cloud_outlined,
                  title: 'Cloud Sync',
                  value: 'Off',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'Support',
              rows: [
                _SettingsRow(
                  icon: Icons.help_outline,
                  title: 'Help',
                ),
                _SettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Feedback',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'About',
              rows: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'App Version',
                ),
                const _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                ),
                const _SettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: .w600),
          ),
        ),
        ClipRRect(
          borderRadius: .circular(18),
          child: ColoredBox(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  rows[index],
                  if (index < rows.length - 1)
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (trailing != null)
                trailing!
              else if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
