import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnable = true;

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
                _SettingsRow(
                  icon: Icons.currency_exchange,
                  title: 'Currency',
                  value: 'RM (MYR)',
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
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}
