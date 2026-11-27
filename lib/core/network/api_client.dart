import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    String? accessToken,
    Dio? dio,
    Future<String> Function()? readAccessToken,
    Future<String> Function(String rejected)? refreshAccessToken,
  }) {
    _accessToken = accessToken;

    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: {'Content-Type': 'application/json'},
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = readAccessToken == null
                ? _accessToken
                : await readAccessToken();
            if (options.extra['sessionRetried'] == true &&
                options.headers['Authorization'] != 'Bearer $token') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  message: '로그인 상태가 변경되어 이전 요청을 중단했어요.',
                ),
              );
              return;
            }
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final authorization = request.headers['Authorization'];
          if (refreshAccessToken == null ||
              error.response?.statusCode != 401 ||
              request.extra['sessionRetried'] == true ||
              authorization is! String ||
              !authorization.startsWith('Bearer ')) {
            handler.next(error);
            return;
          }
          try {
            final token = await refreshAccessToken(authorization.substring(7));
            request.extra['sessionRetried'] = true;
            request.headers['Authorization'] = 'Bearer $token';
            handler.resolve(await _dio.fetch<dynamic>(request));
          } on DioException catch (retry) {
            handler.next(retry);
          } catch (refreshError) {
            handler.next(
              DioException(
                requestOptions: request,
                error: refreshError,
                response: error.response,
              ),
            );
          }
        },
      ),
    );
  }

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  late final Dio _dio;
  String? _accessToken;

  Dio get dio => _dio;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }
}
