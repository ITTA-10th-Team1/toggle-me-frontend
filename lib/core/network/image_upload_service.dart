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
  ImageUploadService(this._apiClient, {Dio Function()? uploadClientFactory})
    : _uploadClientFactory = uploadClientFactory ?? (() => Dio());

  final ApiClient _apiClient;
  final Dio Function() _uploadClientFactory;

  static const int maxFileSize = 10 * 1024 * 1024;
  static const int maxImageDimension = 1600;
  static const int jpegQuality = 85;

  /// 이미지 바이트를 JPEG로 변환하고 크기 조절
  Future<Uint8List> _convertToJpeg(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const FormatException('이미지 파일이 비어 있어요. 다른 사진을 선택해 주세요.');
    }

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FormatException(
        '이 사진 형식은 지원하지 않아요. JPEG 또는 PNG 사진을 선택해 주세요.',
      );
    }

    final orientedImage = img.bakeOrientation(decodedImage);

    final needsResize =
        orientedImage.width > maxImageDimension ||
        orientedImage.height > maxImageDimension;

    final resizedImage = needsResize
        ? img.copyResize(
            orientedImage,
            width: orientedImage.width >= orientedImage.height
                ? maxImageDimension
                : null,
            height: orientedImage.height > orientedImage.width
                ? maxImageDimension
                : null,
            maintainAspect: true,
          )
        : orientedImage;

    return Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: jpegQuality),
    );
  }

  Future<String> upload(Uint8List imageBytes) async {
    final convertedBytes = await _convertToJpeg(imageBytes);

    if (convertedBytes.isEmpty) {
      throw Exception('이미지 파일이 비어 있습니다.');
    }

    if (convertedBytes.length > maxFileSize) {
      throw const FormatException('사진이 10MB를 초과해요. 더 작은 사진을 선택해 주세요.');
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

    final uploadResult = ImageUploadResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    // 2. S3에 JPEG 이미지 업로드
    final s3Dio = _uploadClientFactory();
    s3Dio.options.connectTimeout = const Duration(seconds: 30);
    s3Dio.options.sendTimeout = const Duration(seconds: 60);
    s3Dio.options.receiveTimeout = const Duration(seconds: 30);
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
