import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/app_currency.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:buku555/screens/login_screen.dart';
import 'package:buku555/data/transaction_exporter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buku555/data/transaction_importer.dart';
import 'package:buku555/data/receipt_storage.dart';

// import 'package:buku555/data/theme_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // final bool _notificationEnable = true;
  bool _isSigningOut = false;
  bool _isResettingLocalData = false;

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

  // String _themeLabel(ThemeMode mode) {
  //   return switch (mode) {
  //     ThemeMode.system => 'System',
  //     ThemeMode.light => 'Light',
  //     ThemeMode.dark => 'Dark',
  //   };
  // }

  // Future<void> _chooseTheme() async {
  //   final currentMode = ThemePreferences.instance.current.value;

  //   final selectedMode = await showDialog<ThemeMode>(
  //     context: context,
  //     builder: (dialogContext) => SimpleDialog(
  //       title: const Text('Choose app theme'),
  //       children: [
  //         for (final mode in ThemeMode.values)
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(dialogContext, mode),
  //             child: Row(
  //               children: [
  //                 Expanded(child: Text(_themeLabel(mode))),
  //                 if (mode == currentMode)
  //                   const Icon(Icons.check, color: Colors.teal),
  //               ],
  //             ),
  //           ),
  //       ],
  //     ),
  //   );

  //   if (!mounted || selectedMode == null) return;

  //   await ThemePreferences.instance.save(selectedMode);
  // }

  Future<void> _exportTransactions() async {
    try {
      final renderObject = context.findRenderObject();

      final sharePositionOrigin = renderObject is RenderBox
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : null;

      final missingReceiptCount = await TransactionExporter.exportAll(
        sharePositionOrigin: sharePositionOrigin,
      );

      if (!mounted) return;

      if (missingReceiptCount == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No transactions to export yet.'),
            ),
          );
      } else {
        final message = missingReceiptCount == 0
            ? 'Export file is ready.'
            : missingReceiptCount == 1
            ? 'Export file is ready. 1 receipt image was missing.'
            : 'Export file is ready. $missingReceiptCount receipt images were missing.';

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message)),
          );
      }
    } catch (error) {
      debugPrint('Could not export transactions: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export data. Please try again.'),
        ),
      );
    }
  }

  Future<void> _importTransactions() async {
    try {
      final zipFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (zipFile == null || !mounted) return;

      final prepared = await TransactionImporter.prepare(
        await zipFile.readAsBytes(),
      );

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore backup?'),
          content: Text(
            'This backup contains '
            '${prepared.transactionCount} transactions and '
            '${prepared.receiptCount} receipt images. '
            'It will be restored into this empty ledger.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await TransactionImporter.importPrepared(prepared);

      if (!mounted) return;

      final missing = prepared.missingReceiptCount;
      final message = missing == 0
          ? 'Backup restored successfully.'
          : 'Backup restored. $missing receipt image(s) were already missing.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      debugPrint('Could not import backup: $error');

      if (!mounted) return;

      final message = error is StateError
          ? 'Import requires an empty transaction list to prevent duplicates.'
          : 'Could not restore this backup. Check that it is a valid Buku555 ZIP.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showSettingsMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _confirmAndSignOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You’ll need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      final result = await Amplify.Auth.signOut();

      if (!mounted) return;

      if (result is CognitoCompleteSignOut) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      } else if (result is CognitoFailedSignOut) {
        debugPrint('Cognito sign-out failed: ${result.exception.message}');
        _showSettingsMessage('Could not sign out. Please try again.');
      } else {
        _showSettingsMessage('Could not complete sign out. Please try again.');
      }
    } on AuthException catch (error) {
      debugPrint('Sign-out error: ${error.message}');

      if (mounted) {
        _showSettingsMessage('Could not sign out. Please try again.');
      }
    } catch (error) {
      debugPrint('Unexpected sign-out error: $error');

      if (mounted) {
        _showSettingsMessage('Could not sign out. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _confirmAndResetLocalData() async {
    if (_isResettingLocalData) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset data?'),
        content: const Text(
          'This permanently deletes all transactions and receipt images. '
          'Your account and currency setting will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isResettingLocalData = true;
    });

    try {
      await TransactionDatabase.instance.clearAllTransactions();
      await ReceiptStorage.deleteAll();

      if (!mounted) return;
      _showSettingsMessage('App transactions and receipts were deleted.');
    } catch (error, stackTrace) {
      debugPrint('Could not reset app data: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      _showSettingsMessage(
        'Could not finish resetting app data. Some receipt files may remain.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResettingLocalData = false;
        });
      }
    }
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
              title: 'App',
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
                // ValueListenableBuilder<ThemeMode>(
                //   valueListenable: ThemePreferences.instance.current,
                //   builder: (context, mode, child) {
                //     return _SettingsRow(
                //       icon: Icons.brightness_6_outlined,
                //       title: 'App Theme',
                //       value: _themeLabel(mode),
                //       onTap: _chooseTheme,
                //     );
                //   },
                // ),
                // _SettingsRow(
                //   icon: Icons.language_outlined,
                //   title: 'Language',
                //   value: 'English',
                // ),
                // _SettingsRow(
                //   icon: Icons.notifications_none,
                //   title: 'Notification',
                //   showChevron: false,
                //   trailing: Switch(
                //     value: _notificationEnable,
                //     activeTrackColor: Colors.teal,
                //     onChanged: ((value) {
                //       setState(() {
                //         _notificationEnable = value;
                //       });
                //     }),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'Data & Backup',
              rows: [
                _SettingsRow(
                  icon: Icons.file_upload_outlined,
                  title: 'Export Data',
                  onTap: _exportTransactions,
                ),
                _SettingsRow(
                  icon: Icons.file_download_outlined,
                  title: 'Import Data',
                  onTap: _importTransactions,
                ),
                const _SettingsRow(
                  icon: Icons.cloud_outlined,
                  title: 'Cloud Sync',
                  value: 'Off',
                ),
                _SettingsRow(
                  icon: Icons.delete_outline,
                  title: 'Reset Data',
                  onTap: _confirmAndResetLocalData,
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // _SettingsSection(
            //   title: 'Support',
            //   rows: [
            //     const _SettingsRow(
            //       icon: Icons.help_outline,
            //       title: 'Help',
            //     ),
            //     const _SettingsRow(
            //       icon: Icons.mail_outline,
            //       title: 'Feedback',
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 24),
            _SettingsSection(
              title: 'About',
              rows: [
                const _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  value: 'v1.0.0',
                  showChevron: false,
                ),
                // const _SettingsRow(
                //   icon: Icons.privacy_tip_outlined,
                //   title: 'Privacy Policy',
                // ),
                // const _SettingsRow(
                //   icon: Icons.description_outlined,
                //   title: 'Terms of Service',
                // ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSigningOut ? null : _confirmAndSignOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isSigningOut ? 'Signing out…' : 'Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
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
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final rowColor = isDestructive ? Theme.of(context).colorScheme.error : null;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: rowColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: rowColor),
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
