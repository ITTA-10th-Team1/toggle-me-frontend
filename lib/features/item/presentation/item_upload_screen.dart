import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:toggle_me/app/theme/app_colors.dart';

import '../data/item_image_picker.dart';
import 'providers/item_upload_provider.dart';

class ItemUploadScreen extends ConsumerStatefulWidget {
  const ItemUploadScreen({super.key});

  @override
  ConsumerState<ItemUploadScreen> createState() => _ItemUploadScreenState();
}

class _ItemUploadScreenState extends ConsumerState<ItemUploadScreen> {
  final ItemImagePicker _imagePicker = ItemImagePicker();
  final TextEditingController _memoController = TextEditingController();

  bool _isPublic = false;
  int? _selectedCategory;

  final List<_CategoryItem> _categories = const [
    _CategoryItem('화장대'),
    _CategoryItem('거울', imagePath: 'assets/images/img_upload_mirror.png'),
    _CategoryItem('TV'),
    _CategoryItem(
      '냉장고',
      imagePath: 'assets/images/img_upload_refrigerator.png',
    ),
    _CategoryItem('책상'),
  ];

  int? get _selectedFurnitureTypeId {
    switch (_selectedCategory) {
      case 1:
        return 1; // 거울
      case 3:
        return 2; // 냉장고
      default:
        return null; // 아직 ID를 모르는 가구
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

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

  void _removeImage() {
    ref.read(itemUploadProvider.notifier).removeImage();
  }

  Future<void> _showCancelDialog() async {
    final uploadState = ref.read(itemUploadProvider);

    final hasContent =
        uploadState.selectedImage != null ||
        _memoController.text.trim().isNotEmpty;

    if (!hasContent) {
      ref.read(itemUploadProvider.notifier).removeImage();
      if (mounted) context.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기록을 그만할까요?'),
          content: const Text('작성 중인 내용은 저장되지 않아요.'),
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
              child: const Text('나가기'),
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

  Future<void> _handleSubmit() async {
    final uploadState = ref.read(itemUploadProvider);
    final furnitureTypeId = _selectedFurnitureTypeId;

    if (_selectedCategory == null) {
      _showMessage('가구를 먼저 선택해 주세요.');
      return;
    }

    if (furnitureTypeId == null) {
      _showMessage('아직 등록할 수 없는 가구입니다.');
      return;
    }

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
      await ref
          .read(itemUploadProvider.notifier)
          .submit(
            furnitureTypeId: furnitureTypeId,
            memo: _memoController.text.trim(),
            visibility: _isPublic ? 'PUBLIC' : 'PRIVATE',
          );

      if (!mounted) return;

      _showMessage('사진이 기록되었습니다.');
      context.pop();
    } catch (e) {
      debugPrint('아이템 기록 실패 원인: $e');

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageArea(uploadState),
                    const SizedBox(height: 22),
                    _buildTagSection(uploadState),
                    const SizedBox(height: 22),
                    _buildCategorySection(),
                    const SizedBox(height: 22),
                    _buildMemoSection(),
                    const SizedBox(height: 28),
                    _buildVisibilitySection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(uploadState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '어떤 취향을 기록할까요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: AppColors.buttonSecondary,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _showCancelDialog,
              icon: const Icon(Icons.close, size: 21, color: AppColors.black),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(ItemUploadState state) {
    final image = state.selectedImage;

    return GestureDetector(
      onTap: image == null ? _showImagePicker : null,
      child: Container(
        width: double.infinity,
        height: 185,
        decoration: BoxDecoration(
          color: AppColors.uploadBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: const _DashedBorderPainter(
            color: AppColors.primary,
            radius: 14,
          ),
          child: image == null
              ? _buildEmptyImage()
              : _buildSelectedImage(image, state),
        ),
      ),
    );
  }

  Widget _buildEmptyImage() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add, color: AppColors.black, size: 25),
        ),
        SizedBox(height: 10),
        Text(
          '사진을 올려주세요',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImage(File image, ItemUploadState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),
          if (state.isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.white),
                    SizedBox(height: 10),
                    Text(
                      '사진 업로드 중...',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _imageActionButton(Icons.refresh, _showImagePicker),
                const SizedBox(width: 6),
                _imageActionButton(Icons.delete_outline, _removeImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageActionButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.black, size: 20),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildTagSection(ItemUploadState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('AI가 추천하는 태그'),
        const SizedBox(height: 10),
        if (state.selectedImage == null)
          _tagMessage('사진을 선택하면 AI가 태그를 추천해요.')
        else if (state.isUploading)
          _tagMessage('사진 업로드가 완료되면 분석을 시작해요.')
        else if (state.isGeneratingTags)
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8),
              Text('AI가 사진을 분석하고 있어요.'),
            ],
          )
        else if (state.recommendedTags.isEmpty)
          _tagMessage('추천 태그가 없어요. 사진은 그대로 기록할 수 있어요.')
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: state.recommendedTags.map((tag) {
              final selected = state.selectedTags.contains(tag);

              return FilterChip(
                label: Text('#$tag'),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.uploadBackground,
                backgroundColor: AppColors.chipBackground,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                onSelected: (_) {
                  ref.read(itemUploadProvider.notifier).toggleTag(tag);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _tagMessage(String message) {
    return Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('카테고리'),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = _selectedCategory == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
                child: Container(
                  width: 76,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.uploadBackground
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCategoryIcon(category),
                      const SizedBox(height: 5),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(_CategoryItem category) {
    if (category.imagePath == null) {
      return const SizedBox(width: 42, height: 42);
    }

    return Image.asset(
      category.imagePath!,
      width: 42,
      height: 42,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMemoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('메모'),
        const SizedBox(height: 10),
        TextField(
          controller: _memoController,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: '오늘 발견한 취향에 대해 자유롭게 적어보세요',
            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '취향 공개 여부',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'On: 친구에게 공개   Off: 나만 보기',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.toggleOff,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ItemUploadState state) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _showCancelDialog,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.buttonSecondary,
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('취소하기', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                  foregroundColor: AppColors.black,
                  disabledForegroundColor: AppColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : const Text(
                        '기록하기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.name, {this.imagePath});

  final String name;
  final String? imagePath;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), paint);

        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
