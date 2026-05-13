enum UserRole {
  admin,
  trainer,
  member,
  unknown;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.unknown;
    try {
      return UserRole.values.firstWhere((e) => e.name == role);
    } catch (_) {
      return UserRole.unknown;
    }
  }

  String get toStr => name;
}
