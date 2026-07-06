import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/export_helper.dart';

/// Settings screen for inspector profile, export, and backup
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _companyCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyCtrl.text = prefs.getString('company_name') ?? '';
      _inspectorCtrl.text = prefs.getString('inspector_name') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyCtrl.text.trim());
    await prefs.setString('inspector_name', _inspectorCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _inspectorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Inspector Profile ──────────────────────────────
          _SectionTitle(
            icon: Icons.badge_outlined,
            title: 'Inspector Profile',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                TextField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.domain_outlined),
                    hintText: 'e.g. Axiom Technical Services',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inspectorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Inspector Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Your full name',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: Icon(_saved ? Icons.check : Icons.save_outlined, size: 18),
                    label: Text(_saved ? 'Saved!' : 'Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saved ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Export Data ────────────────────────────────────
          _SectionTitle(
            icon: Icons.upload_file_outlined,
            title: 'Export Data',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _ExportRow(
                  icon: Icons.data_object_outlined,
                  title: 'Export as JSON',
                  subtitle: 'All reports in JSON format for backup or sharing',
                  color: AppColors.primary,
                  onTap: () => ExportHelper.exportAsJson(),
                ),
                const Divider(height: 20),
                _ExportRow(
                  icon: Icons.table_chart_outlined,
                  title: 'Export as CSV',
                  subtitle: 'Open in Excel, Google Sheets, or any spreadsheet app',
                  color: AppColors.success,
                  onTap: () => ExportHelper.exportAsCsv(),
                ),
                const Divider(height: 20),
                _ExportRow(
                  icon: Icons.backup_outlined,
                  title: 'Backup Data',
                  subtitle: 'Save a full backup of all your reports',
                  color: AppColors.accent,
                  onTap: () => ExportHelper.backupData(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── App Info ──────────────────────────────────────
          _SectionTitle(
            icon: Icons.info_outline,
            title: 'About',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: const [
                _InfoRow(label: 'App Name', value: 'Site Visit Report'),
                Divider(height: 16),
                _InfoRow(label: 'Version', value: '1.0.0'),
                Divider(height: 16),
                _InfoRow(label: 'Built for', value: 'Axiom Technical Services'),
                Divider(height: 16),
                _InfoRow(label: 'Storage', value: 'SQLite (Local, Offline)'),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
