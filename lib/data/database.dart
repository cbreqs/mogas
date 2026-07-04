import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fuel_receipt.dart';
import '../models/vehicle.dart';

/// SQLite database for persisting vehicles and receipts.
/// Profile sensitive fields are handled separately via flutter_secure_storage.
/// 
/// NOTE: Receipt dates are stored as MM/DD/YYYY strings. All fiscal year
/// filtering is done in Dart after fetching, not in SQL.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mogas.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vehicles (
            vin TEXT PRIMARY KEY,
            makeModel TEXT NOT NULL,
            year TEXT NOT NULL,
            underWeightLimit INTEGER NOT NULL DEFAULT 1,
            fuelType TEXT NOT NULL DEFAULT 'gasoline'
          )
        ''');

        await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId TEXT NOT NULL,
            fuelType TEXT NOT NULL,
            gallons TEXT NOT NULL,
            date TEXT NOT NULL,
            sellerName TEXT NOT NULL,
            sellerStreet TEXT,
            sellerCity TEXT,
            sellerState TEXT,
            sellerZip TEXT,
            imagePath TEXT,
            ocrConfidence REAL,
            FOREIGN KEY (vehicleId) REFERENCES vehicles (vin) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ── Vehicles ──────────────────────────────────────────────────────────────

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'year DESC');
    return rows.map(Vehicle.fromDbMap).toList();
  }

  Future<Vehicle?> getVehicle(String vin) async {
    final db = await database;
    final rows =
        await db.query('vehicles', where: 'vin = ?', whereArgs: [vin]);
    if (rows.isEmpty) return null;
    return Vehicle.fromDbMap(rows.first);
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.insert(
      'vehicles',
      vehicle.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteVehicle(String vin) async {
    final db = await database;
    await db.delete('vehicles', where: 'vin = ?', whereArgs: [vin]);
  }

  Future<void> moveReceipts(String fromVin, String toVin) async {
    final db = await database;
    await db.update(
      'receipts',
      {'vehicleId': toVin},
      where: 'vehicleId = ?',
      whereArgs: [fromVin],
    );
  }

  Future<void> moveReceipt(int receiptId, String toVin) async {
    final db = await database;
    await db.update(
      'receipts',
      {'vehicleId': toVin},
      where: 'id = ?',
      whereArgs: [receiptId],
    );
  }

  Future<void> moveReceiptsAndDeleteVehicle(
      String fromVin, String toVin) async {
    final db = await database;
    await db.update(
      'receipts',
      {'vehicleId': toVin},
      where: 'vehicleId = ?',
      whereArgs: [fromVin],
    );
    await db.delete('vehicles', where: 'vin = ?', whereArgs: [fromVin]);
  }

  // ── Receipts ──────────────────────────────────────────────────────────────

  Future<List<FuelReceipt>> getReceiptsForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'receipts',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return rows.map(FuelReceipt.fromMap).toList();
  }

  Future<List<FuelReceipt>> getAllReceipts() async {
    final db = await database;
    final rows = await db.query('receipts', orderBy: 'date DESC');
    return rows.map(FuelReceipt.fromMap).toList();
  }

  Future<int> saveReceipt(FuelReceipt receipt) async {
    final db = await database;
    return db.insert(
      'receipts',
      receipt.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReceipt(FuelReceipt receipt) async {
    assert(receipt.id != null, 'Cannot update a receipt with no id');
    final db = await database;
    await db.update(
      'receipts',
      receipt.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getUniqueSellers() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT sellerName FROM receipts ORDER BY sellerName ASC',
    );
    return rows.map((r) => r['sellerName'] as String).toList();
  }

  Future<List<String>> getUniqueCities() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT sellerCity FROM receipts WHERE sellerCity != '' ORDER BY sellerCity ASC",
    );
    return rows.map((r) => r['sellerCity'] as String).toList();
  }

  Future<List<String>> getUniqueZips() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT sellerZip FROM receipts WHERE sellerZip != '' ORDER BY sellerZip ASC",
    );
    return rows.map((r) => r['sellerZip'] as String).toList();
  }

  /// Total eligible gallons across all eligible vehicles (≤26,000 lbs).
  /// 
  /// [startDate] and [endDate] are DateTime objects for fiscal year filtering.
  /// Filtering is done in Dart because dates are stored as MM/DD/YYYY strings.
  Future<double> totalEligibleGallons({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    // Fetch all receipts joined with eligible vehicles
    final rows = await db.rawQuery('''
      SELECT r.gallons, r.date
      FROM receipts r
      JOIN vehicles v ON r.vehicleId = v.vin
      WHERE v.underWeightLimit = 1
    ''');

    double total = 0.0;
    for (final row in rows) {
      final dateStr = row['date'] as String? ?? '';
      if (startDate != null || endDate != null) {
        final d = _parseMmDdYyyy(dateStr);
        if (d == null) continue;
        if (startDate != null && d.isBefore(startDate)) continue;
        if (endDate != null && d.isAfter(endDate)) continue;
      }
      total += double.tryParse(row['gallons'] as String? ?? '') ?? 0.0;
    }
    return total;
  }

  Future<double> estimatedRefund({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final gallons =
        await totalEligibleGallons(startDate: startDate, endDate: endDate);
    return gallons * 0.125;
  }

  /// Parses a MM/DD/YYYY or MM-DD-YYYY date string to DateTime.
  /// Also handles 2-digit years (e.g. 10/22/25 → 2025).
  /// Returns null on failure.
  static DateTime? _parseMmDdYyyy(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final normalized = dateStr.replaceAll('-', '/');
      final parts = normalized.split('/');
      if (parts.length == 3) {
        var year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        return DateTime(
          year,
          int.parse(parts[0]), // month
          int.parse(parts[1]), // day
        );
      }
    } catch (_) {}
    return null;
  }
}
