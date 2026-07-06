import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import 'form_screen.dart';
import 'saved_reports_screen.dart';
import 'settings_screen.dart';

/// Home screen with New Report, Saved Reports, and Settings navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  int _totalReports = 0;
  int _draftReports = 0;
  String _inspectorName = '';
  String _companyName = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadSettings();
  }

  Future<void> _loadStats() async {
    final total = await _db.getReportCount();
    final drafts = await _db.getReportsByStatus('draft');
    if (mounted) {
      setState(() {
        _totalReports = total;
        _draftReports = drafts.length;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _inspectorName = prefs.getString('inspector_name') ?? '';
        _companyName = prefs.getString('company_name') ?? 'Axiom Technical Services';
      });
    }
  }

  void _openNewReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormScreen()),
    ).then((_) => _loadStats());
  }

  void _openSavedReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedReportsScreen()),
    ).then((_) => _loadStats());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Company logo area
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.domain,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _companyName.isNotEmpty
                                        ? _companyName
                                        : 'Axiom Technical Services',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'Site Visit Reports',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _openSettings,
                              icon: const Icon(Icons.settings_outlined,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_inspectorName.isNotEmpty)
                          Text(
                            'Welcome, $_inspectorName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const Text(
                            'Field Survey App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats Cards ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Total Reports',
                    value: _totalReports.toString(),
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Drafts',
                    value: _draftReports.toString(),
                    icon: Icons.edit_note_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Submitted',
                    value: (_totalReports - _draftReports).toString(),
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),

          // ── Main Action Cards ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // New Site Visit
                _ActionCard(
                  title: 'New Site Visit',
                  subtitle: 'Start a new property inspection report',
                  icon: Icons.add_location_alt,
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.sectionBg,
                  onTap: _openNewReport,
                  isHighlighted: true,
                ),
                const SizedBox(height: 12),

                // Saved Reports
                _ActionCard(
                  title: 'Saved Reports',
                  subtitle: 'View, search and edit past reports',
                  icon: Icons.folder_open_outlined,
                  iconColor: AppColors.accent,
                  backgroundColor: Colors.white,
                  onTap: _openSavedReports,
                ),
                const SizedBox(height: 12),

                // Settings
                _ActionCard(
                  title: 'Settings',
                  subtitle: 'Inspector info, company name, data export',
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.textSecondary,
                  backgroundColor: Colors.white,
                  onTap: _openSettings,
                ),
                const SizedBox(height: 24),

                // Quick Tips
                _QuickTipsCard(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewReport,
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
              : Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentLight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Quick Tips',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _TipRow(text: 'Reports auto-save as you fill them in'),
          const _TipRow(text: 'Tap GPS button to capture your location'),
          const _TipRow(text: 'Add photos and digital signature per report'),
          const _TipRow(text: 'Export all data as JSON or CSV from Settings'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;
  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accent, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
