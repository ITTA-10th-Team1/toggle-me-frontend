import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ItemImagePicker {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return null;

    return File(image.path);
  }

  Future<File?> pickFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return null;

    return File(image.path);
  }
}
