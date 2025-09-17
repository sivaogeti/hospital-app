import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hospital.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // create tables
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            name TEXT,
            role TEXT NOT NULL,
            salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER,
            gender TEXT,
            contact TEXT,
            created_at TEXT
          )
        ''');

        // seed defaults
        await _seedDefaultUsers(db);
      },
    );
  }

  // ---------- Seeder ----------
  static Future<void> _seedDefaultUsers(Database db) async {
    final defaults = [
      {'username': 'healthagent1', 'password': 'a123', 'role': 'Health Agent', 'name': 'Health Agent 1'},
      {'username': 'doctor1', 'password': 'd123', 'role': 'Doctor', 'name': 'Doctor 1'},
      {'username': 'patient1', 'password': 'p123', 'role': 'Patient', 'name': 'Patient 1'},
    ];

    for (final u in defaults) {
      final salt = _randomSalt();
      final saltHex = _hexEncode(salt);
      final hash = _hashPassword(u['password']!, salt);
      final createdAt = DateTime.now().toIso8601String();

      try {
        await db.insert('users', {
          'username': u['username'],
          'name': u['name'],
          'role': u['role'],
          'salt': saltHex,
          'password_hash': hash,
          'created_at': createdAt,
        });
      } catch (_) {
        // ignore duplicates if rerun
      }
    }
  }

  // ---------- PBKDF2 helpers ----------
  static const int _iterations = 200000;

  static List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  static List<int> _int32(int i) =>
      [(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff];

  static List<int> _pbkdf2Raw(String password, List<int> salt, int iterations, int dkLen) {
    final hLen = 32;
    final passwordBytes = utf8.encode(password);
    final blocks = (dkLen + hLen - 1) ~/ hLen;
    final result = <int>[];

    for (var block = 1; block <= blocks; block++) {
      final blockIndex = _int32(block);
      final initial = <int>[]..addAll(salt)..addAll(blockIndex);
      var u = _hmacSha256(passwordBytes, initial);
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = _hmacSha256(passwordBytes, u);
        for (var j = 0; j < t.length; j++) t[j] ^= u[j];
      }
      result.addAll(t);
    }
    return result.sublist(0, dkLen);
  }

  static String _hashPassword(String password, List<int> salt) {
    final dk = _pbkdf2Raw(password, salt, _iterations, 32);
    return _hexEncode(dk);
  }

  static List<int> _randomSalt([int length = 16]) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  static String _hexEncode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
