
// lib/db.dart
import 'dart:convert' show utf8;
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  /// Public accessor used across the app
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  // ------------------------ OPEN / CREATE / SEED -------------------------

  static Future<Database> _open() async {
    final base = await getDatabasesPath();
    final dbPath = p.join(base, 'hospital.db');

    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (Database db, int version) async {
        await _createSchema(db);
        await _seedDefaultUsers(db);
        await _maybeSeedSamplePatients(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Ensure schema exists if user upgrades from older versions.
        await _createSchema(db);
      },
      onOpen: (Database db) async {
        // Safety net: ensure at least 1 user exists
        final ucount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        );
        if ((ucount ?? 0) == 0) {
          await _seedDefaultUsers(db);
        }
        // Safety: ensure vitals table exists
        await _ensureVitalsTable(db);
      },
    );

    // Debug: print the DB path once
    // ignore: avoid_print
    print('[DB] Opened at: $dbPath');
    return db;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        name TEXT,
        role TEXT NOT NULL,
        salt TEXT NOT NULL,           -- hex string
        password_hash TEXT NOT NULL,  -- sha256(salt_bytes + password_bytes)
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        village TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(name)');

    await _ensureVitalsTable(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blood_sugar_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fk_patient_id INTEGER NOT NULL,
        test_type TEXT NOT NULL,         -- RBS | FBS | PPBS | HbA1c
        fasting INTEGER,                 -- mg/dL
        pp INTEGER,                      -- mg/dL
        random INTEGER,                  -- mg/dL
        hba1c REAL,                      -- percent
        last_meal_time TEXT,
        history TEXT,
        symptoms TEXT,
        notes TEXT,
        followup_days INTEGER DEFAULT 0,
        sent_to_doctor INTEGER DEFAULT 0,
        recorded_by TEXT,
        recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (fk_patient_id) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_bst_patient ON blood_sugar_tests(fk_patient_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bst_recorded_at ON blood_sugar_tests(recorded_at)');
  }

  static Future<void> _ensureVitalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fk_patient_id INTEGER NOT NULL,
        pulse INTEGER,
        temperature REAL,
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        spo2 INTEGER,
        respiratory_rate INTEGER,
        notes TEXT,
        recorded_by TEXT,
        recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (fk_patient_id) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');
  }

  // ------------------------ PASSWORD / HASH HELPERS ----------------------

  /// Generate a random 16-byte salt and return as lowercase hex.
  static String genSaltHex([int lengthBytes = 16]) {
    final rnd = Random.secure();
    final salt = Uint8List(lengthBytes);
    for (var i = 0; i < salt.length; i++) {
      salt[i] = rnd.nextInt(256);
    }
    return bytesToHex(salt);
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.trim();
    final out = Uint8List(cleaned.length ~/ 2);
    for (int i = 0; i < cleaned.length; i += 2) {
      out[i ~/ 2] = int.parse(cleaned.substring(i, i + 2), radix: 16);
    }
    return out;
  }

  /// Public: convert bytes to lowercase hex
  static String bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Public: sha256( salt_bytes + password_bytes ), return lowercase hex
  static String hashSaltPlusPassword(String saltHex, String password) {
    final saltBytes = _hexToBytes(saltHex);
    final passBytes = utf8.encode(password);
    final combined = Uint8List(saltBytes.length + passBytes.length)
      ..setRange(0, saltBytes.length, saltBytes)
      ..setRange(saltBytes.length, saltBytes.length + passBytes.length, passBytes);
    return sha256.convert(combined).toString();
  }

  static Future<void> _seedDefaultUsers(Database db) async {
    Future<void> insertUser({
      required String username,
      required String name,
      required String role,
      required String password,
    }) async {
      final saltHex = genSaltHex();
      final hash = hashSaltPlusPassword(saltHex, password);

      await db.insert('users', {
        'username': username,
        'name': name,
        'role': role,
        'salt': saltHex,
        'password_hash': hash,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await insertUser(
      username: 'healthagent1',
      name: 'Health Agent 1',
      role: 'Health Agent',
      password: 'a123',
    );
    await insertUser(
      username: 'doctor1',
      name: 'Doctor 1',
      role: 'Doctor',
      password: 'd123',
    );
    await insertUser(
      username: 'patient1',
      name: 'Patient 1',
      role: 'Patient',
      password: 'p123',
    );
  }

  static Future<void> _maybeSeedSamplePatients(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM patients'),
    );
    if ((count ?? 0) > 0) return;

    final seed = [
      {'name': 'Ravi Kumar', 'age': 54, 'gender': 'M', 'village': 'Kakinada'},
      {'name': 'Lakshmi Devi', 'age': 47, 'gender': 'F', 'village': 'Rajahmundry'},
      {'name': 'Sita Ram', 'age': 62, 'gender': 'M', 'village': 'Amalapuram'},
    ];
    for (final p in seed) {
      await db.insert('patients', p);
    }
  }

  // ----------------------------- USERS API --------------------------------

  /// Fetch a single user row by username+role (returns null if not found)
  static Future<Map<String, dynamic>?> getUserByUsernameRole(
      String username, String role) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND role = ?',
      whereArgs: [username.trim(), role.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Verify password using sha256(salt_bytes + password_bytes)
  static Future<bool> verifyUser(
      String username, String role, String password) async {
    final row = await getUserByUsernameRole(username, role);
    if (row == null) return false;

    final saltHex = (row['salt'] as String).trim();
    final stored = ((row['password_hash'] ?? '') as String).trim().toLowerCase();
    final computed = hashSaltPlusPassword(saltHex, password);
    return computed == stored;
  }

  // ---------------------------- PATIENTS API ------------------------------

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return db.rawQuery('''
      SELECT id, name, IFNULL(age, 0) AS age, IFNULL(gender, '') AS gender, IFNULL(village, '') AS village
      FROM patients
      ORDER BY name COLLATE NOCASE
    ''');
  }

  static Future<int> insertPatient(Map<String, dynamic> values) async {
    final db = await database;
    return db.insert('patients', values);
  }

  // ------------------------------ VITALS API ------------------------------

  static Future<int> insertVitals(Map<String, dynamic> values) async {
    final db = await database;
    return db.insert('vitals', values);
  }

  // ------------------------ BLOOD SUGAR TESTS API -------------------------

  /// Insert a blood sugar test. Expects a map with at least:
  /// fk_patient_id, test_type, and one of (random/fasting/pp/hba1c).
  /// Optional fields: last_meal_time, history, symptoms, notes,
  /// followup_days, recorded_by
  static Future<int> insertBloodSugar(Map<String, dynamic> values) async {
    final db = await database;

    final nowIso = DateTime.now().toIso8601String();

    final row = <String, Object?>{
      'fk_patient_id': values['fk_patient_id'],
      'test_type': values['test_type'], // RBS | FBS | PPBS | HbA1c
      'fasting': values['fasting'],
      'pp': values['pp'],
      'random': values['random'],
      'hba1c': values['hba1c'],
      'last_meal_time': values['last_meal_time'],
      'history': values['history'],
      'symptoms': values['symptoms'],
      'notes': values['notes'],
      'followup_days': values['followup_days'] ?? 0,
      'sent_to_doctor': values['sent_to_doctor'] ?? 0,
      'recorded_by': values['recorded_by'],
      'recorded_at': values['recorded_at'] ?? nowIso,
    };

    return db.insert('blood_sugar_tests', row);
  }

  static Future<List<Map<String, dynamic>>> getRecentSugarTests({int limit = 50}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        id,
        fk_patient_id,
        test_type,
        fasting,
        pp,
        random,
        hba1c,
        last_meal_time,
        history,
        symptoms,
        notes,
        followup_days,
        sent_to_doctor,
        recorded_by,
        recorded_at
      FROM blood_sugar_tests
      ORDER BY datetime(recorded_at) DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Bulk mark tests as sent_to_doctor = 1
  static Future<int> markSugarTestsSent(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return db.rawUpdate(
      'UPDATE blood_sugar_tests SET sent_to_doctor = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  
  // ------------------------------ REPORTS API -----------------------------

  /// Returns a simple integer map for dashboard/report tiles.
  /// Keys expected by reports_page.dart: patients, vitals, tests, inventory
  static Future<Map<String, int>> countsForReports() async {
    final db = await database;
    final patients = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM patients')) ?? 0;
    final tests = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM blood_sugar_tests')) ?? 0;
    final vitals = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM vitals')) ?? 0;
    // If you later add an inventory table, replace this with an actual count.
    final inventory = 0;
    return {
      'patients': patients,
      'vitals': vitals,
      'tests': tests,
      'inventory': inventory,
    };
  }

}
