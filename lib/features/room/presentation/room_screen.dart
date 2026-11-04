import '../../../core/widgets/app_notice.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'room_scene_bridge.dart';
import 'room_camera_config.dart';
import 'room_mood_hashtags.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import '../domain/room_visibility.dart';

/// 중간 발표용 방: 거울·냉장고 고정 배치, 고정 카메라와 가구 터치.
/// 나머지 세 가구는 미배치 상태로 표시합니다.
class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    this.onProfile,
    this.onNotifications,
    this.onRecord,
    this.onGuestbook,
    this.onShop,
    this.onMood,
    this.onFriends,
    this.onCategory,
    this.onFurnitureTap,
    this.moodHashtags = const [],
    this.initialVisibility = RoomVisibility.socialOn,
    this.onVisibilityChanged,
  });

  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;
  final VoidCallback? onRecord;
  final VoidCallback? onGuestbook;
  final VoidCallback? onShop;
  final VoidCallback? onMood;
  final VoidCallback? onFriends;
  final ValueChanged<String>? onCategory;

  /// Pinboard integration callback. Stable IDs: mirror, fridge.
  /// onCategory remains as a fallback for the existing router.
  final ValueChanged<String>? onFurnitureTap;

  /// Empty means no analysis result; sample tags are passed only by the demo route.
  final List<RoomMoodHashtag> moodHashtags;

  final RoomVisibility initialVisibility;

  /// Return the server-confirmed visibility. Null keeps local presentation mode.
  final Future<RoomVisibility> Function(RoomVisibility)? onVisibilityChanged;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late bool _isPublic;
  bool _savingVisibility = false;
  int _visibilityGeneration = 0;
  final bool _hasNewNotifications = false; // TODO: 알림 API 연결

  bool _modelLoaded = false;
  bool _modelFailed = false;
  int _attempt = 0;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.initialVisibility.isPublic;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVisibility != widget.initialVisibility) {
      _visibilityGeneration++;
      _isPublic = widget.initialVisibility.isPublic;
      _savingVisibility = false;
    }
  }

  Future<void> _changeVisibility(bool value) async {
    if (_savingVisibility) return;
    final save = widget.onVisibilityChanged;
    if (save == null) {
      setState(() => _isPublic = value);
      return;
    }
    final generation = ++_visibilityGeneration;
    setState(() => _savingVisibility = true);
    try {
      final confirmed = await save(
        value ? RoomVisibility.socialOn : RoomVisibility.socialOff,
      );
      if (mounted && generation == _visibilityGeneration) {
        setState(() => _isPublic = confirmed.isPublic);
      }
    } catch (error) {
      if (mounted && generation == _visibilityGeneration) {
        showAppNotice(context, '공개 설정을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted && generation == _visibilityGeneration) {
        setState(() => _savingVisibility = false);
      }
    }
  }

  void _startTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_modelLoaded) setState(() => _modelFailed = true);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _openFurniture(String id) {
    if (id != 'mirror' && id != 'fridge') return;
    if (widget.onFurnitureTap != null) {
      widget.onFurnitureTap!(id);
    } else if (widget.onCategory != null) {
      widget.onCategory!(id == 'mirror' ? '거울' : '냉장고');
    } else {
      _showFurnitureDetails((id == 'mirror' ? '거울' : '냉장고', id));
    }
  }

  bool _isPlaced(String id) => id == 'mirror' || id == 'fridge';

  void _showFurnitureDetails((String, String) category) {
    final placed = _isPlaced(category.$2);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.$1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(placed ? '방에 배치되어 있어요.' : '아직 배치되지 않았어요.'),
              const SizedBox(height: 16),
              if (placed &&
                  (widget.onFurnitureTap != null || widget.onCategory != null))
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openFurniture(category.$2);
                  },
                  child: const Text('핀보드 보기'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _background = AppColors.roomBackground;
  static const _orange = AppColors.roomAccent;
  static const _ivory = AppColors.surfaceMuted;
  static const _categories = [
    ('화장대', 'vanity'),
    ('거울', 'mirror'),
    ('TV', 'tv'),
    ('책상', 'desk'),
    ('냉장고', 'fridge'),
  ];

  Widget _svg(String name, {double? width, double? height}) => name == 'profile'
      ? ClipOval(
          child: Image.asset(
            'assets/room/raster/profile.png',
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        )
      : SvgPicture.asset(
          'assets/room/icons/$name.svg',
          width: width,
          height: height,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '마이페이지',
                          onPressed: widget.onProfile,
                          icon: _svg('profile', width: 46, height: 46),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 46,
                            minHeight: 46,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '알림',
                          onPressed: widget.onNotifications,
                          icon: _svg(
                            _hasNewNotifications
                                ? 'notification_new'
                                : 'notification',
                            width: 46,
                            height: 46,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 46,
                            minHeight: 46,
                          ),
                        ),
                        const Spacer(),
                        RoomModeToggle(
                          isOn: _isPublic,
                          isLoading: _savingVisibility,
                          onChanged: _changeVisibility,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RoomMoodHashtags(tags: widget.moodHashtags),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ModelViewer(
                            key: ValueKey('demo-room-v8-$_attempt'),
                            src: 'assets/models/toggleme_room.glb',
                            alt: '나의 3D 방',
                            backgroundColor: _background,
                            loading: Loading.eager,
                            cameraControls: false,
                            disablePan: true,
                            disableTap: true,
                            autoRotate: false,
                            disableZoom: true,
                            cameraOrbit: RoomCameraConfig.orbit,
                            fieldOfView: RoomCameraConfig.fieldOfView,
                            minFieldOfView: RoomCameraConfig.fieldOfView,
                            maxFieldOfView: RoomCameraConfig.fieldOfView,
                            minCameraOrbit: RoomCameraConfig.orbit,
                            maxCameraOrbit: RoomCameraConfig.orbit,
                            interactionPrompt: InteractionPrompt.none,
                            relatedCss: 'model-viewer { touch-action: none; }',
                            javascriptChannels: {
                              JavascriptChannel(
                                'RoomFurniture',
                                onMessageReceived: (message) {
                                  if (mounted && _modelLoaded) {
                                    _openFurniture(message.message);
                                  }
                                },
                              ),
                              JavascriptChannel(
                                'RoomStatus',
                                onMessageReceived: (message) {
                                  if (!mounted) return;
                                  _loadTimer?.cancel();
                                  setState(() {
                                    _modelLoaded = message.message == 'loaded';
                                    _modelFailed = !_modelLoaded;
                                  });
                                },
                              ),
                            },
                            relatedJs: roomSceneBridge,
                          ),
                          if (!_modelLoaded)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _background,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_modelFailed)
                                    const CircularProgressIndicator(),
                                  const SizedBox(height: 12),
                                  Text(
                                    _modelFailed
                                        ? '3D 방을 불러오지 못했어요.'
                                        : '3D 방을 불러오는 중이에요.',
                                  ),
                                  if (_modelFailed)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _attempt++;
                                          _modelFailed = false;
                                          _modelLoaded = false;
                                        });
                                        _startTimer();
                                      },
                                      child: const Text('다시 시도'),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showFurnitureDetails(category),
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: _ivory),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Semantics(
                                  label:
                                      '${category.$1}, ${_isPlaced(category.$2) ? '배치됨' : '미배치'}',
                                  image: true,
                                  child: _isPlaced(category.$2)
                                      ? Image.asset(
                                          'assets/room/raster/${category.$2}_color.png',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.contain,
                                        )
                                      : ColorFiltered(
                                          colorFilter: const ColorFilter.matrix(
                                            [
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                            ],
                                          ),
                                          child: Opacity(
                                            opacity: 0.45,
                                            child: Image.asset(
                                              'assets/room/raster/${category.$2}.png',
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                ),
                                Text(
                                  category.$1,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 112,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: widget.onRecord,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              '기록하기',
                              style: AppTextStyles.buttonSmall,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              backgroundColor: _orange,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: _ivory,
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _nav('guestbook', '방명록', widget.onGuestbook),
                                _nav('shop', '상점', widget.onShop),
                                _nav('mood', '무드레포트', widget.onMood),
                                _nav('friends', '친구목록', widget.onFriends),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(String asset, String tooltip, VoidCallback? onPressed) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: _svg(asset, width: 46, height: 46),
        iconSize: 46,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      );
}
