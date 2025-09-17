import 'package:sqflite/sqflite.dart';
import 'db.dart';

class PatientService {
  static Future<int> addPatient(String name, int age, String gender, String contact) async {
    final db = await DBHelper.database;
    return await db.insert('patients', {
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final db = await DBHelper.database;
    return await db.query(
      'patients',
      where: 'name LIKE ? OR id LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await DBHelper.database;
    return await db.query('patients', orderBy: 'created_at DESC');
  }
}
