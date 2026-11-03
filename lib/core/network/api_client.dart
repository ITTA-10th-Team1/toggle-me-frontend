import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({String? accessToken}) {
    _accessToken = accessToken;

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.toggleme.site',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessToken;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

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
