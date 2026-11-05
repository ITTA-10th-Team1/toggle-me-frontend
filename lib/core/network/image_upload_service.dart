import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

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
  static const int maxImageDimension = 1600;
  static const int jpegQuality = 85;

  /// 긴 변을 최대 1600px로 줄이고 JPEG로 변환
  Future<Uint8List> _convertToJpeg(File image) async {
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('이미지를 읽을 수 없습니다.');
    }

    final resizedImage = img.copyResize(
      decodedImage,
      width: decodedImage.width >= decodedImage.height
          ? maxImageDimension
          : null,
      height: decodedImage.height > decodedImage.width
          ? maxImageDimension
          : null,
      maintainAspect: true,
    );

    return Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: jpegQuality),
    );
  }

  Future<String> upload(File image) async {
    final convertedBytes = await _convertToJpeg(image);

    if (convertedBytes.isEmpty) {
      throw Exception('이미지 파일이 비어 있습니다.');
    }

    if (convertedBytes.length > maxFileSize) {
      throw Exception('변환된 이미지가 10MB를 초과합니다.');
    }

    const contentType = 'image/jpeg';

    // 1. 백엔드에 업로드 URL 요청
    final response = await _apiClient.dio.post(
      '/api/v1/images/upload-url',
      data: {
        'contentType': contentType,
        'contentLength': convertedBytes.length,
      },
    );

    print('이미지 업로드 URL 응답: ${response.data}');

    final uploadResult = ImageUploadResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    // 2. S3에 JPEG 이미지 업로드
    final s3Dio = Dio();
    final headers = Map<String, dynamic>.from(uploadResult.headers);

    headers.putIfAbsent('Content-Type', () => contentType);

    try {
      await s3Dio.put(
        uploadResult.uploadUrl,
        data: convertedBytes,
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
