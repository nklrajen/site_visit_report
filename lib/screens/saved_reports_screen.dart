import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/site_visit_report.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import 'form_screen.dart';

/// Browse, search, and manage all saved site visit reports
class SavedReportsScreen extends StatefulWidget {
  const SavedReportsScreen({super.key});

  @override
  State<SavedReportsScreen> createState() => _SavedReportsScreenState();
}

class _SavedReportsScreenState extends State<SavedReportsScreen> {
  final _db = DatabaseHelper();
  final _searchCtrl = TextEditingController();
  List<SiteVisitReport> _reports = [];
  List<SiteVisitReport> _filtered = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
    _searchCtrl.addListener(_applyFilter);
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final all = await _db.getAllReports();
    setState(() {
      _reports = all;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    List<SiteVisitReport> source;

    if (_filterStatus == 'draft') {
      source = _reports.where((r) => r.status == 'draft').toList();
    } else if (_filterStatus == 'submitted') {
      source = _reports.where((r) => r.status == 'submitted').toList();
    } else {
      source = _reports;
    }

    if (query.isEmpty) {
      setState(() => _filtered = source);
      return;
    }

    setState(() {
      _filtered = source.where((r) {
        return (r.customerName?.toLowerCase().contains(query) ?? false) ||
            (r.loanNumber?.toLowerCase().contains(query) ?? false) ||
            (r.locality?.toLowerCase().contains(query) ?? false) ||
            (r.landMark?.toLowerCase().contains(query) ?? false) ||
            (r.bankName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _deleteReport(SiteVisitReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report?'),
        content: Text(
          'Delete the report for "${report.displayTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && report.id != null) {
      await _db.deleteReport(report.id!);
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editReport(SiteVisitReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(existingReport: report)),
    ).then((_) => _loadReports());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Saved Reports'),
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, loan no., locality...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () { _searchCtrl.clear(); _applyFilter(); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: _reports.length,
                  isSelected: _filterStatus == 'all',
                  onTap: () => setState(() { _filterStatus = 'all'; _applyFilter(); }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Drafts',
                  count: _reports.where((r) => r.status == 'draft').length,
                  isSelected: _filterStatus == 'draft',
                  color: AppColors.accent,
                  onTap: () => setState(() { _filterStatus = 'draft'; _applyFilter(); }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Submitted',
                  count: _reports.where((r) => r.status == 'submitted').length,
                  isSelected: _filterStatus == 'submitted',
                  color: AppColors.success,
                  onTap: () => setState(() { _filterStatus = 'submitted'; _applyFilter(); }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Report list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _ReportCard(
                          report: _filtered[i],
                          onEdit: () => _editReport(_filtered[i]),
                          onDelete: () => _deleteReport(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchCtrl.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No reports yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Create a new site visit to get started',
            style: const TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final SiteVisitReport report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(report.updatedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 4),
              if (report.displaySubtitle.isNotEmpty)
                Text(
                  report.displaySubtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (report.locality != null && report.locality!.isNotEmpty) ...[
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      report.locality!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (report.latitude != null)
                    _ActionBtn(
                      icon: Icons.gps_fixed,
                      label: 'View on Maps',
                      color: AppColors.success,
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://maps.google.com/?q=${report.latitude},${report.longitude}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  const Spacer(),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: AppColors.primary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 16),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
