// lib/services/db_service.dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'hospital.db');

    // If you packaged a prepopulated DB in assets/hospital.db, copy it on first run:
    if (!await File(dbPath).exists()) {
      try {
        final data = await rootBundle.load('assets/data/hospital.db');
        final bytes = data.buffer.asUint8List();
        await File(dbPath).create(recursive: true);
        await File(dbPath).writeAsBytes(bytes);
      } catch (_) {
        // no prepackaged DB; we'll create tables next
      }
    }

    final db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table (and any other migrations)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        name TEXT,
        role TEXT NOT NULL,
        salt TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT
      );
    ''');

    // you can create other tables here...
  }

  // helper
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
