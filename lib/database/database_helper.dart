import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/site_visit_report.dart';

/// SQLite database manager for all site visit reports
/// Handles CRUD operations, search, and data export
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'site_visit_reports.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'reports';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables on first launch
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        bank_name TEXT,
        loan_number TEXT,
        date_of_visit TEXT,
        customer_name TEXT,
        property_address_deed TEXT,
        property_address_site TEXT,
        dim_north_deed TEXT,
        dim_south_deed TEXT,
        dim_east_deed TEXT,
        dim_west_deed TEXT,
        dim_north_site TEXT,
        dim_south_site TEXT,
        dim_east_site TEXT,
        dim_west_site TEXT,
        bound_north_deed TEXT,
        bound_south_deed TEXT,
        bound_east_deed TEXT,
        bound_west_deed TEXT,
        bound_north_site TEXT,
        bound_south_site TEXT,
        bound_east_site TEXT,
        bound_west_site TEXT,
        land_extent_deed TEXT,
        land_extent_site TEXT,
        any_changes_in_boundaries TEXT,
        land_mark TEXT,
        locality TEXT,
        age_of_property TEXT,
        road_type TEXT,
        property_identified TEXT,
        road_width TEXT,
        nearest_bus_stop TEXT,
        usage_of_building TEXT,
        railway_station TEXT,
        no_of_unit TEXT,
        nearest_hospital TEXT,
        no_of_floor TEXT,
        structure TEXT,
        occupancy TEXT,
        bore_well TEXT,
        septic_tank TEXT,
        oht TEXT,
        compound_wall TEXT,
        sump TEXT,
        eb_services TEXT,
        floor_type TEXT,
        demarcated TEXT,
        no_of_tenants TEXT,
        maintenance_of_building TEXT,
        roof TEXT,
        stage_construction_percent TEXT,
        type_of_locality TEXT,
        latitude REAL,
        longitude REAL,
        google_point TEXT,
        photos_paths TEXT,
        signature_path TEXT,
        inspector_name TEXT,
        company_name TEXT
      )
    ''');

    // Index for fast search
    await db.execute('CREATE INDEX idx_customer_name ON $_tableName(customer_name)');
    await db.execute('CREATE INDEX idx_status ON $_tableName(status)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ─── CRUD Operations ────────────────────────────────────────────

  /// Insert a new report, returns inserted id
  Future<int> insertReport(SiteVisitReport report) async {
    final db = await database;
    final map = report.toMap()..remove('id');
    return await db.insert(_tableName, map);
  }

  /// Update existing report by report_id
  Future<int> updateReport(SiteVisitReport report) async {
    final db = await database;
    report.updatedAt = DateTime.now();
    return await db.update(
      _tableName,
      report.toMap(),
      where: 'report_id = ?',
      whereArgs: [report.reportId],
    );
  }

  /// Upsert: insert if new, update if exists
  Future<void> saveReport(SiteVisitReport report) async {
    final existing = await getReportByReportId(report.reportId);
    if (existing == null) {
      await insertReport(report);
    } else {
      await updateReport(report);
    }
  }

  /// Delete report by id
  Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Get single report by report_id (UUID)
  Future<SiteVisitReport?> getReportByReportId(String reportId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
    if (maps.isEmpty) return null;
    return SiteVisitReport.fromMap(maps.first);
  }

  /// Get all reports ordered by newest first
  Future<List<SiteVisitReport>> getAllReports() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'updated_at DESC');
    return maps.map((m) => SiteVisitReport.fromMap(m)).toList();
  }

  /// Search reports by customer name, locality, loan number, or landmark
  Future<List<SiteVisitReport>> searchReports(String query) async {
    final db = await database;
    final q = '%${query.toLowerCase()}%';
    final maps = await db.query(
      _tableName,
      where: '''
        lower(customer_name) LIKE ? OR
        lower(locality) LIKE ? OR
        lower(loan_number) LIKE ? OR
        lower(land_mark) LIKE ? OR
        lower(bank_name) LIKE ?
      ''',
      whereArgs: [q, q, q, q, q],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => SiteVisitReport.fromMap(m)).toList();
  }

  /// Get reports by status
  Future<List<SiteVisitReport>> getReportsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => SiteVisitReport.fromMap(m)).toList();
  }

  /// Total report count
  Future<int> getReportCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Export all reports as list of maps (for JSON/CSV export)
  Future<List<Map<String, dynamic>>> exportAllReports() async {
    final db = await database;
    return await db.query(_tableName, orderBy: 'created_at ASC');
  }
}
