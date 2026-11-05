class ImageUploadResult {
  const ImageUploadResult({
    required this.uploadUrl,
    required this.imageKey,
    required this.headers,
  });

  final String uploadUrl;
  final String imageKey;
  final Map<String, String> headers;

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as Map? ?? {};

    return ImageUploadResult(
      uploadUrl: json['uploadUrl'] as String,
      imageKey: json['imageKey'] as String,
      headers: rawHeaders.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }
}

class ImageAnalysisResult {
  const ImageAnalysisResult({required this.analysisId});

  final String analysisId;

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(analysisId: json['analysisId'].toString());
  }
}

class ImageAnalysisStatus {
  const ImageAnalysisStatus({required this.status, this.tags = const []});

  final String status;
  final List<String> tags;

  factory ImageAnalysisStatus.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    final rawTags = result?['tags'] as List<dynamic>? ?? [];

    return ImageAnalysisStatus(
      status: json['status'] as String? ?? 'FAILED',
      tags: rawTags.map((tag) => tag.toString()).toList(),
    );
  }
}
