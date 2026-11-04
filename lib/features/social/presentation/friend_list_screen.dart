import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/fake_social_service.dart';
import '../data/models/social_user.dart';
import '../data/models/social_user_page.dart';
import '../data/social_service.dart';
import 'widgets/friend_list_message.dart';
import 'widgets/friend_list_tile.dart';
import 'widgets/friend_search_bar.dart';

/// 소셜 친구 목록 화면 (이슈 #21)
/// service를 안 넣으면 가짜 서비스를 써요. 테스트에서는 원하는 서비스를 넣을 수 있어요.
// TODO(social): 입장 제한(로그인 회원 + 본인 방 ON) 확인. 지금은 메인 홈에서 버튼을 숨기는 방식
class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key, this.service});

  final SocialService? service;

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  /// 입력이 이만큼 멈추면 검색 요청 (debounce)
  static const _searchDelay = Duration(milliseconds: 300);

  /// 목록 끝에서 이만큼 남았을 때 다음 20명을 미리 불러와요.
  static const _loadMoreThreshold = 300.0;

  // TODO(api): 소셜 API가 나오면 진짜 서비스로 교체
  late final SocialService _service = widget.service ?? FakeSocialService();

  final _searchController = TextEditingController();
  // keepScrollOffset: false → 목록을 새로 불러오면 맨 위부터 보여줘요.
  final _scrollController = ScrollController(keepScrollOffset: false);
  Timer? _searchTimer;

  List<SocialUser> _users = [];
  String? _nextCursor;
  String _query = ''; // 지금 화면에 보이는 결과의 검색어 ('' = 기본 목록)

  bool _isLoading = true; // 첫 묶음 불러오는 중
  bool _isLoadingMore = false; // 아래쪽 추가 묶음 불러오는 중
  bool _hasError = false; // 첫 묶음 실패
  bool _loadMoreFailed = false; // 추가 묶음 실패
  int? _visitingMemberId; // 놀러가기 확인 중인 사람

  /// 요청 번호. 새 목록 요청마다 1씩 올려서, 늦게 도착한 옛날 응답은 버려요.
  /// (예: 'ca' 결과가 'cat' 결과보다 늦게 와서 덮어쓰는 것을 막음)
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 화면에 새로 들어오면 목록을 새로 구성 (정책 10)
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────── 목록 불러오기 ─────────

  /// 검색어가 있으면 검색, 없으면 기본 목록
  Future<SocialUserPage> _request({String? cursor}) {
    if (_query.isEmpty) return _service.fetchUsers(cursor: cursor);
    return _service.searchUsers(query: _query, cursor: cursor);
  }

  /// 목록을 비우고 처음부터 다시 불러와요. (검색어 변경, 다시 시도)
  void _reload() {
    setState(() {
      _users = [];
      _nextCursor = null;
      _isLoading = true;
      _isLoadingMore = false;
      _hasError = false;
      _loadMoreFailed = false;
    });
    _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    final requestId = ++_requestId;
    try {
      final page = await _request();
      if (!mounted || requestId != _requestId) return; // 옛날 응답이면 버림
      setState(() {
        _users = [...page.users];
        _nextCursor = page.nextCursor;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// 다음 20명 이어 받기 (정책 9)
  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_isLoading || _isLoadingMore || cursor == null) return;

    final requestId = _requestId;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final page = await _request(cursor: cursor);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _users.addAll(page.users);
        _nextCursor = page.nextCursor;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadMoreFailed = true;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    // 실패했을 때는 스크롤로 자동 재요청하지 않고 [다시 시도] 버튼을 기다려요.
    if (_loadMoreFailed) return;
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      _loadMore();
    }
  }

  // ───────── 검색 ─────────

  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    final query = text.trim();

    // 검색어를 지우면 바로 기본 목록으로 (화면설계서 3번)
    if (query.isEmpty) {
      if (_query.isEmpty) return; // 이미 기본 목록
      _query = '';
      _reload();
      return;
    }

    // 입력이 0.3초 멈추면 검색
    _searchTimer = Timer(_searchDelay, () {
      if (query == _query) return; // 같은 검색어면 다시 요청 안 함
      _query = query;
      _reload();
    });
  }

  // ───────── 놀러가기 ─────────

  Future<void> _onVisitPressed(SocialUser user) async {
    if (_visitingMemberId != null) return; // 중복 클릭 방지
    setState(() => _visitingMemberId = user.memberId);
    try {
      final canVisit = await _service.canVisit(user.memberId);
      if (!mounted) return;
      if (canVisit) {
        // push: 현재 화면을 남겨둬서, 돌아오면 목록과 스크롤 위치가 그대로예요.
        // TODO(router): 다른 사용자 마이홈 경로가 생기면 교체 (예: /room/:memberId)
        context.push(AppRoutes.room);
      } else {
        // 상대가 방금 OFF로 바꿈 → 목록에서 빼고 안내 (문구에 상대 이름 넣지 않음)
        setState(() => _users.removeWhere((u) => u.memberId == user.memberId));
        // TODO(design): 임시 문구, 디자이너 확인 필요
        _showMessage('지금은 방문할 수 없는 방이에요.');
      }
    } catch (_) {
      if (mounted) _showMessage('네트워크 연결을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _visitingMemberId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ───────── 화면 ─────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  // TODO(router): 메인 홈(#03)이 AppRoutes.room 인지 확인
                  onBack: () => context.go(AppRoutes.room),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FriendSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_hasError) {
      return FriendListMessage(
        message: '목록을 불러오지 못했어요.',
        actionLabel: '다시 시도',
        onAction: _reload,
      );
    }
    if (_users.isEmpty) {
      // TODO(design): 기본 목록이 비었을 때 문구 확인 필요
      return FriendListMessage(
        message: _query.isEmpty ? '아직 보여줄 친구가 없어요.' : '검색 결과가 없어요.',
      );
    }

    // 맨 아래 한 칸: 추가 로딩 표시 또는 [다시 시도]
    final hasFooter = _isLoadingMore || _loadMoreFailed;

    return ListView.separated(
      controller: _scrollController,
      // 목록을 끌어내리면 키보드가 내려가요.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _users.length + (hasFooter ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _users.length) return _buildFooter();
        final user = _users[index];
        return FriendListTile(
          key: ValueKey(user.memberId),
          user: user,
          isVisiting: _visitingMemberId == user.memberId,
          onVisit: () => _onVisitPressed(user),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return FriendListMessage(
        message: '목록을 불러오지 못했어요.',
        actionLabel: '다시 시도',
        onAction: _loadMore,
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

/// 상단: 동그란 뒤로가기 버튼 + 가운데 '친구 목록' 제목
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // 폭을 화면 전체로 잡아야 왼쪽 뒤로가기 버튼이 영역 안에 들어와서 눌려요.
    return SizedBox(
      width: double.infinity,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: SizedBox(
              width: 52,
              height: 52,
              child: IconButton(
                tooltip: '뒤로가기',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.iconButtonBackground,
                ),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Text(
            '친구 목록',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
