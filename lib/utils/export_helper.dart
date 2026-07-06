import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

/// Handles exporting reports to JSON and CSV formats
class ExportHelper {
  static final _db = DatabaseHelper();

  /// Export all reports as a JSON file and share it
  static Future<void> exportAsJson() async {
    final data = await _db.exportAllReports();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/site_visit_reports_${_timestamp()}.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Site Visit Reports - JSON Export',
    );
  }

  /// Export all reports as a CSV file and share it
  static Future<void> exportAsCsv() async {
    final data = await _db.exportAllReports();

    if (data.isEmpty) return;

    // Build CSV rows
    final headers = data.first.keys.toList();
    final rows = <List<dynamic>>[headers];
    for (final row in data) {
      rows.add(headers.map((h) => row[h]?.toString() ?? '').toList());
    }

    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/site_visit_reports_${_timestamp()}.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Site Visit Reports - CSV Export',
    );
  }

  /// Backup entire database as JSON
  static Future<void> backupData() async {
    await exportAsJson();
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
