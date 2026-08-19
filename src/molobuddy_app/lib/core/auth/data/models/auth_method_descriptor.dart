enum AuthMethodKind {
  emailPassword('email_password'),
  federated('federated');

  const AuthMethodKind(this.wireValue);

  final String wireValue;

  static AuthMethodKind? fromWireValue(String value) {
    for (final kind in values) {
      if (kind.wireValue == value) {
        return kind;
      }
    }
    return null;
  }
}

enum AuthMethodAvailability {
  available('available'),
  comingSoon('coming_soon'),
  unavailable('unavailable');

  const AuthMethodAvailability(this.wireValue);

  final String wireValue;

  static AuthMethodAvailability? fromWireValue(String value) {
    for (final availability in values) {
      if (availability.wireValue == value) {
        return availability;
      }
    }
    return null;
  }
}

final class AuthMethodDescriptor {
  const AuthMethodDescriptor({
    required this.providerId,
    required this.kind,
    required this.displayNameKey,
    required this.availability,
    required this.enabledPlatforms,
    required this.supportsLinking,
    required this.sortOrder,
  });

  final String providerId;
  final AuthMethodKind kind;
  final String displayNameKey;
  final AuthMethodAvailability availability;
  final Set<String> enabledPlatforms;
  final bool supportsLinking;
  final int sortOrder;

  static const emailPassword = AuthMethodDescriptor(
    providerId: 'password',
    kind: AuthMethodKind.emailPassword,
    displayNameKey: 'auth.provider.emailPassword',
    availability: AuthMethodAvailability.available,
    enabledPlatforms: {'android', 'ios', 'web'},
    supportsLinking: true,
    sortOrder: 10,
  );

  static const googleComingSoon = AuthMethodDescriptor(
    providerId: 'google.com',
    kind: AuthMethodKind.federated,
    displayNameKey: 'auth.provider.google',
    availability: AuthMethodAvailability.comingSoon,
    enabledPlatforms: {'android', 'ios', 'web'},
    supportsLinking: true,
    sortOrder: 20,
  );
}
