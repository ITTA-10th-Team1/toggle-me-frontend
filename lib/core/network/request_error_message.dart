import 'package:dio/dio.dart';

import 'member_api.dart';

String requestErrorMessage(Object error) {
  if (error is MemberApiException) return error.message;
  if (error is DioException) {
    final cause = error.error;
    if (cause is MemberApiException) return cause.message;
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.response?.statusCode == 401) return '다시 로그인해 주세요.';
    return '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
  if (error is FormatException) return error.message;
  return '요청을 처리하지 못했어요. 다시 시도해 주세요.';
}
