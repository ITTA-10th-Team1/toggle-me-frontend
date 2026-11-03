import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/item_image_picker.dart';
import 'providers/item_upload_provider.dart';

class ItemUploadScreen extends ConsumerStatefulWidget {
  const ItemUploadScreen({super.key});

  @override
  ConsumerState<ItemUploadScreen> createState() => _ItemUploadScreenState();
}

class _ItemUploadScreenState extends ConsumerState<ItemUploadScreen> {
  static const Color _accentColor = Color(0xFFFF813B);
  static const Color _backgroundColor = Color(0xFFFDFBF3);

  final ItemImagePicker _imagePicker = ItemImagePicker();
  final TextEditingController _memoController = TextEditingController();

  bool _isPublic = false;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  // 갤러리 또는 카메라 선택
  Future<void> _showImagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 사진 선택 후 업로드 및 AI 분석 시작
  Future<void> _pickImage(ImageSource source) async {
    final File? image;

    if (source == ImageSource.gallery) {
      image = await _imagePicker.pickFromGallery();
    } else {
      image = await _imagePicker.pickFromCamera();
    }

    if (!mounted || image == null) return;

    await ref.read(itemUploadProvider.notifier).setImage(image);

    if (!mounted) return;

    final state = ref.read(itemUploadProvider);

    if (state.errorMessage != null) {
      _showMessage(state.errorMessage!);
    }
  }

  // 사진 삭제
  void _removeImage() {
    ref.read(itemUploadProvider.notifier).removeImage();
  }

  // 취소 확인
  Future<void> _showCancelDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기록을 취소할까요?'),
          content: const Text('작성 중인 내용이 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('계속 작성'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('취소하기'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      ref.read(itemUploadProvider.notifier).removeImage();
      context.pop();
    }
  }

  // 냉장고 사진 기록
  Future<void> _handleSubmit() async {
    final uploadState = ref.read(itemUploadProvider);

    if (uploadState.selectedImage == null) {
      _showMessage('사진을 먼저 선택해 주세요.');
      return;
    }

    if (uploadState.isUploading) {
      _showMessage('사진 업로드가 진행 중입니다.');
      return;
    }

    if (uploadState.imageKey == null) {
      _showMessage('사진 업로드에 실패했습니다. 다시 선택해 주세요.');
      return;
    }

    try {
      await ref.read(itemUploadProvider.notifier).submit();

      if (!mounted) return;

      _showMessage('사진이 기록되었습니다.');
      context.pop();
    } catch (e) {
      if (!mounted) return;

      _showMessage('기록에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(itemUploadProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: _showCancelDialog,
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: const Text(
          '아이템 기록하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('사진'),
              const SizedBox(height: 12),
              _buildImageArea(uploadState),
              const SizedBox(height: 28),

              _buildSectionTitle('가구 선택'),
              const SizedBox(height: 12),
              _buildCategoryArea(),
              const SizedBox(height: 28),

              _buildSectionTitle('AI 추천 태그'),
              const SizedBox(height: 12),
              _buildTagArea(uploadState),
              const SizedBox(height: 28),

              _buildSectionTitle('메모'),
              const SizedBox(height: 12),
              _buildMemoArea(),
              const SizedBox(height: 20),

              _buildVisibilityArea(),
              const SizedBox(height: 32),

              _buildSubmitButton(uploadState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildImageArea(ItemUploadState uploadState) {
    final image = uploadState.selectedImage;

    return GestureDetector(
      onTap: image == null ? _showImagePicker : null,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: image == null
            ? _buildEmptyImage()
            : _buildSelectedImage(image, uploadState),
      ),
    );
  }

  Widget _buildEmptyImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 12),
        const Text('사진을 추가해 주세요', style: TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        Text(
          '갤러리 또는 카메라에서 선택할 수 있어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSelectedImage(File image, ItemUploadState uploadState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),

          if (uploadState.isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('사진 업로드 중...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _imageActionButton(
                  icon: Icons.refresh,
                  onPressed: _showImagePicker,
                ),
                const SizedBox(width: 8),
                _imageActionButton(
                  icon: Icons.delete_outline,
                  onPressed: _removeImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black87),
      ),
    );
  }

  Widget _buildCategoryArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.kitchen_outlined, size: 30, color: _accentColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '냉장고',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  '냉장고에 보관한 아이템을 기록해요.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: _accentColor),
        ],
      ),
    );
  }

  Widget _buildTagArea(ItemUploadState uploadState) {
    if (uploadState.selectedImage == null) {
      return _tagMessage('사진을 선택하면 AI가 태그를 추천해요.');
    }

    if (uploadState.isUploading) {
      return _tagMessage('사진 업로드가 완료되면 분석을 시작해요.');
    }

    if (uploadState.isGeneratingTags) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _accentColor,
              ),
            ),
            SizedBox(width: 10),
            Text('AI가 사진을 분석하고 있어요.'),
          ],
        ),
      );
    }

    if (uploadState.recommendedTags.isEmpty) {
      return _tagMessage('추천 태그가 없어요. 사진은 그대로 기록할 수 있어요.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: uploadState.recommendedTags.map((tag) {
        final isSelected = uploadState.selectedTags.contains(tag);

        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          selectedColor: const Color(0xFFFFE4D4),
          checkmarkColor: _accentColor,
          onSelected: (_) {
            ref.read(itemUploadProvider.notifier).toggleTag(tag);
          },
        );
      }).toList(),
    );
  }

  Widget _tagMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildMemoArea() {
    return TextField(
      controller: _memoController,
      maxLength: 200,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: '아이템에 대한 메모를 남겨보세요.',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterText: '${_memoController.text.length}/200',
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _buildVisibilityArea() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('공개 설정', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                '기록 공개 여부를 설정해요.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: _isPublic,
          activeThumbColor: _accentColor,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ItemUploadState uploadState) {
    final isDisabled =
        uploadState.isSubmitting ||
        uploadState.isUploading ||
        uploadState.selectedImage == null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: uploadState.isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '기록하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
