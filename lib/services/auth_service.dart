
// lib/auth_service.dart
import '../modules/db.dart';

class AuthService {
  /// Try to log in with username, password, and role.
  /// Returns the user row (Map) if successful, or null if invalid.
  static Future<Map<String, dynamic>?> login(
      String username, String password, String role) async {
    final row = await DBHelper.getUserByUsernameRole(username, role);
    if (row == null) return null;

    final ok = await DBHelper.verifyUser(username, role, password);
    if (!ok) return null;

    return row;
  }

  /// Register a new user. Returns true on success, false if duplicate username+role.
  static Future<bool> register(String username, String password, String role,
      {String? name}) async {
    final db = await DBHelper.database;

    // prevent duplicates
    final existing = await DBHelper.getUserByUsernameRole(username, role);
    if (existing != null) return false;

    // make salt + hash using DBHelper helpers
    final saltHex = DBHelper.genSaltHex();
    final hash = DBHelper.hashSaltPlusPassword(saltHex, password);

    await db.insert('users', {
      'username': username.trim(),
      'name': name ?? username.trim(),
      'role': role.trim(),
      'salt': saltHex,
      'password_hash': hash,
      'created_at': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
