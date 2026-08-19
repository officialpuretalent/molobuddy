import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';

final class HttpAuthProviderCatalogueService
    implements AuthProviderCatalogueService {
  factory HttpAuthProviderCatalogueService({
    required Dio dio,
    required String baseUrl,
    AuthProviderCatalogueService? offlineFallback,
  }) {
    return HttpAuthProviderCatalogueService._(
      dio,
      baseUrl.replaceFirst(RegExp(r'/$'), ''),
      offlineFallback,
    );
  }

  HttpAuthProviderCatalogueService._(
    this._dio,
    this._baseUrl,
    this._offlineFallback,
  );

  final Dio _dio;
  final String _baseUrl;
  final AuthProviderCatalogueService? _offlineFallback;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadProviders() async {
    try {
      final response = await _dio.get<Object>(
        '$_baseUrl/v1/auth/providers',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final providers = _parseResponse(response.data);
      if (providers == null) {
        return _fallbackOr(
          const AuthFailure(AuthFailureKind.providerUnavailable),
        );
      }
      return AuthSuccess(providers);
    } on DioException {
      return _fallbackOr(const AuthFailure(AuthFailureKind.networkUnavailable));
    } on FormatException {
      return _fallbackOr(
        const AuthFailure(AuthFailureKind.providerUnavailable),
      );
    }
  }

  Future<AuthResult<List<AuthMethodDescriptor>>> _fallbackOr(
    AuthFailure failure,
  ) async {
    final fallback = _offlineFallback;
    if (fallback != null) {
      return fallback.loadProviders();
    }
    return AuthError(failure);
  }

  static List<AuthMethodDescriptor>? _parseResponse(Object? data) {
    if (data is! Map<String, Object?>) {
      return null;
    }
    final responseData = data['data'];
    if (responseData is! Map<String, Object?>) {
      return null;
    }
    final rawProviders = responseData['providers'];
    if (rawProviders is! List<Object?>) {
      return null;
    }

    final providers = <AuthMethodDescriptor>[];
    for (final rawProvider in rawProviders) {
      final provider = _parseProvider(rawProvider);
      if (provider == null) {
        throw const FormatException('Invalid authentication provider.');
      }
      providers.add(provider);
    }
    providers.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return List.unmodifiable(providers);
  }

  static AuthMethodDescriptor? _parseProvider(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final providerId = value['providerId'];
    final kindValue = value['kind'];
    final displayNameKey = value['displayNameKey'];
    final availabilityValue = value['availability'];
    final platformsValue = value['enabledPlatforms'];
    final supportsLinking = value['supportsLinking'];
    final sortOrder = value['sortOrder'];
    if (providerId is! String ||
        kindValue is! String ||
        displayNameKey is! String ||
        availabilityValue is! String ||
        platformsValue is! List<Object?> ||
        supportsLinking is! bool ||
        sortOrder is! int) {
      return null;
    }
    final kind = AuthMethodKind.fromWireValue(kindValue);
    final availability = AuthMethodAvailability.fromWireValue(
      availabilityValue,
    );
    final platforms = platformsValue.whereType<String>().toSet();
    if (kind == null ||
        availability == null ||
        platforms.length != platformsValue.length) {
      return null;
    }
    return AuthMethodDescriptor(
      providerId: providerId,
      kind: kind,
      displayNameKey: displayNameKey,
      availability: availability,
      enabledPlatforms: Set.unmodifiable(platforms),
      supportsLinking: supportsLinking,
      sortOrder: sortOrder,
    );
  }
}
