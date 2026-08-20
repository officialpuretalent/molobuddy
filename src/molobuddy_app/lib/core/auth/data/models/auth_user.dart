final class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  /// The name to greet this person by, or `null` when they have told us none.
  ///
  /// Deliberately never falls back to [email]. An address is not a name, and
  /// rendering one as a display-size greeting put the unmasked address on
  /// screen directly above the masked address the session took care to
  /// produce. A greeting with no name is better than a greeting with the
  /// wrong thing in it.
  String? get greetingName {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? null : name;
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
