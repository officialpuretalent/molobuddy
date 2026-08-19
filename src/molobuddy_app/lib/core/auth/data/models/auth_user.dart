final class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  String get greetingName {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? email : name;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            id == other.id &&
            email == other.email &&
            displayName == other.displayName;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName);
}
