import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class ImageUploadResult {
  final String uploadUrl;
  final String imageKey;
  final Map<String, dynamic> headers;
  final DateTime expiresAt;

  ImageUploadResult({
    required this.uploadUrl,
    required this.imageKey,
    required this.headers,
    required this.expiresAt,
  });

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageUploadResult(
      uploadUrl: json['uploadUrl'] as String,
      imageKey: json['imageKey'] as String,
      headers: Map<String, dynamic>.from(json['headers'] as Map),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class ImageUploadService {
  ImageUploadService(this._apiClient);

  final ApiClient _apiClient;

  static const int maxFileSize = 10 * 1024 * 1024;

  String _contentType(String path) {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      default:
        throw Exception('JPEG, PNG, HEIC 이미지만 업로드할 수 있습니다.');
    }
  }

  Future<String> upload(File image) async {
    final fileSize = await image.length();

    if (fileSize == 0) {
      throw Exception('이미지 파일이 비어 있습니다.');
    }

    if (fileSize > maxFileSize) {
      throw Exception('이미지는 10MB 이하만 업로드할 수 있습니다.');
    }

    final contentType = _contentType(image.path);

    // 1. 백엔드에 업로드 URL 요청
    final response = await _apiClient.dio.post(
      '/api/v1/images/upload-url',
      data: {'contentType': contentType, 'contentLength': fileSize},
    );

    final uploadResult = ImageUploadResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    // 2. S3에 이미지 업로드
    // 백엔드 인증 인터셉터가 없는 별도 Dio 사용
    final s3Dio = Dio();

    final headers = Map<String, dynamic>.from(uploadResult.headers);

    // 서버가 Content-Type을 내려주지 않은 경우에만 보충
    headers.putIfAbsent('Content-Type', () => contentType);

    try {
      final bytes = await image.readAsBytes();

      await s3Dio.put(
        uploadResult.uploadUrl,
        data: bytes,
        options: Options(
          headers: headers,
          contentType: contentType,
          responseType: ResponseType.plain,
        ),
      );
    } finally {
      s3Dio.close();
    }

    return uploadResult.imageKey;
  }
}
