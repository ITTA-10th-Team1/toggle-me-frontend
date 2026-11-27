import 'package:image_picker/image_picker.dart';

class ItemImagePicker {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    return image;
  }

  Future<XFile?> pickFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    return image;
  }
}
