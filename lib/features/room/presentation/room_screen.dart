import '../../../core/widgets/app_notice.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'room_scene_bridge.dart';
import 'room_web_view_stub.dart'
    if (dart.library.js_interop) 'room_web_view.dart';
import 'room_camera_config.dart';
import 'room_lighting_config.dart';
import 'room_bottom_bar.dart';
import 'room_mood_hashtags.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import '../domain/room_visibility.dart';
import '../domain/room_data.dart';
import '../../guide/presentation/guide_book_icon.dart';
import 'room_action_icon.dart';

/// 중간 발표용 방: 거울·냉장고 고정 배치, 고정 카메라와 가구 터치.
/// 나머지 세 가구는 미배치 상태로 표시합니다.
class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    this.onProfile,
    this.onLogout,
    this.onGuide,
    this.onRecord,
    this.onGuestbook,
    this.onShop,
    this.onMood,
    this.onShare,
    this.onEdit,
    this.onCategory,
    this.onFurnitureTap,
    this.moodHashtags = const [],
    this.initialVisibility = RoomVisibility.socialOn,
    this.onVisibilityChanged,
    this.furniture,
  });

  final VoidCallback? onProfile;
  final List<RoomFurniture>? furniture;
  final VoidCallback? onLogout;
  final VoidCallback? onGuide;
  final VoidCallback? onRecord;
  final VoidCallback? onGuestbook;
  final VoidCallback? onShop;
  final VoidCallback? onMood;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
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
    if (!_isPlaced(id)) return;
    if (id != 'mirror' && id != 'fridge') return;
    if (widget.onFurnitureTap != null) {
      widget.onFurnitureTap!(id);
    } else if (widget.onCategory != null) {
      widget.onCategory!(id == 'mirror' ? '거울' : '냉장고');
    } else {
      _showFurnitureDetails((id == 'mirror' ? '거울' : '냉장고', id));
    }
  }

  bool _isPlaced(String id) => widget.furniture == null
      ? id == 'mirror' || id == 'fridge'
      : widget.furniture!.any((e) => e.code == id && !e.hidden);

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
                    child: Text(category.$1, style: AppTextStyles.head2),
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
                  child: const Text('기록 보기'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _background = AppColors.roomBackground;
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
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '마이페이지',
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onProfile,
                          icon: _svg('profile', width: 46, height: 46),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 46,
                            maxWidth: 46,
                            minHeight: 46,
                            maxHeight: 46,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: '로그아웃',
                          onPressed: widget.onLogout,
                          icon: _svg('logout', width: 46, height: 46),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 46,
                            height: 46,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: '이용가이드',
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onGuide,
                          icon: const GuideBookIcon(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 46,
                            maxWidth: 46,
                            minHeight: 46,
                            maxHeight: 46,
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
                  const SizedBox(height: 22),
                  RoomMoodHashtags(tags: widget.moodHashtags),
                  Padding(
                    padding: const EdgeInsets.only(right: 20, top: 14),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: '방 편집',
                        onPressed:
                            widget.onEdit ??
                            () => showAppNotice(context, '방 편집 기능은 준비 중이에요.'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 46,
                          height: 46,
                        ),
                        icon: const RoomActionIcon(edit: true),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (kIsWeb)
                            RoomWebView(
                              key: ValueKey('web-room-$_attempt'),
                              bridge: widget.furniture == null
                                  ? roomSceneBridge
                                  : roomSceneBridgeFor(widget.furniture!),
                              onFurniture: (value) {
                                if (mounted && _modelLoaded) {
                                  _openFurniture(value);
                                }
                              },
                              onStatus: (value) {
                                if (!mounted) return;
                                _loadTimer?.cancel();
                                setState(() {
                                  _modelLoaded = value == 'loaded';
                                  _modelFailed = !_modelLoaded;
                                });
                              },
                            )
                          else
                            ModelViewer(
                              key: ValueKey('demo-room-v12-$_attempt'),
                              src: 'assets/models/toggleme_room.glb',
                              alt: '나의 3D 방',
                              backgroundColor: _background,
                              environmentImage: RoomLightingConfig.environment,
                              exposure: RoomLightingConfig.exposure,
                              shadowIntensity:
                                  RoomLightingConfig.shadowIntensity,
                              shadowSoftness: RoomLightingConfig.shadowSoftness,
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
                              relatedCss:
                                  'model-viewer { touch-action: none; }',
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
                                      _modelLoaded =
                                          message.message == 'loaded';
                                      _modelFailed = !_modelLoaded;
                                    });
                                  },
                                ),
                              },
                              relatedJs: widget.furniture == null
                                  ? roomSceneBridge
                                  : roomSceneBridgeFor(widget.furniture!),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: RoomBottomBar(
                      onRecord: widget.onRecord,
                      onGuestbook: widget.onGuestbook,
                      onShop: widget.onShop,
                      onMood: widget.onMood,
                      onShare:
                          widget.onShare ??
                          () => showAppNotice(context, '공유 기능은 준비 중이에요.'),
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
}
