import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/services/http_auth_provider_catalogue_service.dart';

void main() {
  test(
    'maps the API data.providers envelope without using a fallback',
    () async {
      final adapter = _JsonAdapter({
        'data': {
          'providers': [
            {
              'providerId': 'password',
              'kind': 'email_password',
              'displayNameKey': 'auth.provider.emailPassword',
              'availability': 'available',
              'enabledPlatforms': ['web', 'android', 'ios'],
              'supportsLinking': true,
              'sortOrder': 10,
            },
            {
              'providerId': 'google.com',
              'kind': 'federated',
              'displayNameKey': 'auth.provider.google',
              'availability': 'coming_soon',
              'enabledPlatforms': ['web', 'android', 'ios'],
              'supportsLinking': true,
              'sortOrder': 20,
            },
          ],
        },
        'meta': {'requestId': 'request-preview'},
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final service = HttpAuthProviderCatalogueService(
        dio: dio,
        baseUrl: 'https://api.example.test/',
      );

      final result = await service.loadProviders();

      expect(adapter.requestPath, 'https://api.example.test/v1/auth/providers');
      expect(result, isA<AuthSuccess<List<AuthMethodDescriptor>>>());
      final methods = (result as AuthSuccess<List<AuthMethodDescriptor>>).value;
      expect(methods, hasLength(2));
      expect(methods.first.providerId, 'password');
      expect(methods.first.displayNameKey, 'auth.provider.emailPassword');
      expect(methods.first.sortOrder, 10);
      expect(methods.last.providerId, 'google.com');
      expect(methods.last.availability, AuthMethodAvailability.comingSoon);
      expect(methods.last.sortOrder, 20);
    },
  );

  test('rejects a response that omits the standard data envelope', () async {
    final dio = Dio()
      ..httpClientAdapter = _JsonAdapter({'providers': <Object?>[]});
    final service = HttpAuthProviderCatalogueService(
      dio: dio,
      baseUrl: 'https://api.example.test',
    );

    final result = await service.loadProviders();

    expect(result, isA<AuthError<List<AuthMethodDescriptor>>>());
    expect(
      (result as AuthError<List<AuthMethodDescriptor>>).failure.kind,
      AuthFailureKind.providerUnavailable,
    );
  });
}

final class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);

  final Map<String, Object?> body;
  String? requestPath;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.path;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
