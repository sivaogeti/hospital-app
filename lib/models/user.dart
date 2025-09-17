// lib/models/user.dart
class User {
  final int? id;
  final String username;
  final String? name;
  final String role;
  final String salt;
  final String passwordHash;
  final String? createdAt;

  User({this.id, required this.username, this.name, required this.role, required this.salt, required this.passwordHash, this.createdAt});

  factory User.fromMap(Map<String, Object?> m) {
    return User(
      id: m['id'] as int?,
      username: m['username'] as String,
      name: m['name'] as String?,
      role: m['role'] as String,
      salt: m['salt'] as String,
      passwordHash: m['password_hash'] as String,
      createdAt: m['created_at'] as String?,
    );
  }
}
