import 'package:dio/dio.dart';
import 'package:random_magic/core/constants/api_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// Riverpod provider that exposes the configured [Dio] singleton.
///
/// Kept alive for the lifetime of the app — creating a new [Dio] per request
/// would discard connection pooling and interceptor state.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return _buildDio();
}

/// Constructs and configures the [Dio] instance.
///
/// Separated from the provider so tests can call [_buildDio] directly
/// without needing a [ProviderContainer].
Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'User-Agent': ApiConstants.userAgent,
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(_ScryfallErrorInterceptor());
  return dio;
}

/// Interceptor that passes [DioException]s through unchanged.
///
/// Typed failure mapping (404 → [CardNotFoundFailure], etc.) is the
/// responsibility of [ScryfallApiClient] (RM-11), not the transport layer.
class _ScryfallErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
