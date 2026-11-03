import 'models/social_user.dart';

/// 가짜 데이터 한 명. 진짜 서버라면 서버 안에만 있을 정보(방 상태)도 함께 가져요.
class FakeMember {
  const FakeMember({
    required this.user,
    this.isRoomOn = true,
    this.closesBeforeVisit = false,
  });

  final SocialUser user;

  /// 방 ON 여부. OFF면 목록·검색에서 빠져요. (정책 4)
  final bool isRoomOn;

  /// 목록에는 보이지만 놀러가기 직전에 OFF로 바꾼 사람 (오류 처리 확인용)
  final bool closesBeforeVisit;
}

/// 가짜 데이터에서 '나'의 회원 번호. 목록·검색에서 빠져요. (정책 4)
const fakeMyMemberId = 1;

FakeMember _member(
  int id,
  String nickname,
  String handle, {
  bool photo = false,
  bool roomOn = true,
  bool closesBeforeVisit = false,
}) {
  return FakeMember(
    user: SocialUser(
      memberId: id,
      nickname: nickname,
      handle: handle,
      profileImageUrl: photo
          ? 'https://picsum.photos/seed/toggle$id/200'
          : null,
    ),
    isRoomOn: roomOn,
    closesBeforeVisit: closesBeforeVisit,
  );
}

/// 가짜 회원 전체: 나 1명 + 목록에 보이는 50명(2~51번) + 방 OFF 4명
final List<FakeMember> fakeMembers = [
  // 나 (목록에서 빠져야 함)
  _member(fakeMyMemberId, '나', 'toggle_me'),

  // 목록에 보이는 50명
  _member(2, '토글러', 'toggler_01', photo: true),
  _member(3, 'Mint Cat', 'mintcat'),
  _member(4, '고양이집사', 'cat.butler22', photo: true),
  _member(5, 'lazy sunday', 'lazysunday'),
  _member(6, '토글토글', 'toggle_2', closesBeforeVisit: true),
  _member(7, '밤산책', 'night.walk'),
  _member(8, '커피한잔', 'coffee_one', photo: true),
  _member(9, 'Cozy Room', 'cozyroom'),
  _member(10, '레트로감성', 'retro_mood'),
  _member(11, '식물집사', 'plant.parent', photo: true),
  _member(12, 'Toggle Kim', 'toggle.kim'),
  _member(13, '노을빛', 'sunset_glow'),
  _member(14, '책읽는밤', 'book_night', photo: true),
  _member(15, 'Blue Whale', 'bluewhale'),
  _member(16, '빈티지러버', 'vintage_lover'),
  _member(17, '캣타워', 'cat_tower', photo: true),
  _member(18, 'dreamy', 'dreamy99'),
  _member(19, '미니멀리스트', 'minimal.ist'),
  _member(20, '오늘의방', 'todays_room', photo: true),
  _member(21, 'Lumi', 'lumi_lumi'),
  _member(22, '포근포근', 'pogeun'),
  _member(23, '우주먹방', 'space.eat', photo: true),
  _member(24, 'Pixel Art', 'pixel_art'),
  _member(25, '레코드판', 'vinyl_record'),
  _member(26, '고요한아침', 'quiet.morning', photo: true),
  _member(27, 'Moon Light', 'moonlight_7'),
  _member(28, '방꾸미기', 'room_deco'),
  _member(29, '체크무늬', 'check_pattern', photo: true),
  _member(30, 'sleepy cat', 'sleepycat'),
  _member(31, '초록이', 'green_green'),
  _member(32, '다락방', 'attic_room', photo: true),
  _member(33, 'Honey Bee', 'honeybee'),
  _member(34, '여름바다', 'summer.sea'),
  _member(35, '겨울숲', 'winter_forest', photo: true),
  _member(36, 'Toggler Lee', 'toggler_lee'),
  _member(37, '몽글몽글', 'monggle'),
  _member(38, '따뜻한조명', 'warm_light', photo: true),
  _member(39, 'Paper Plane', 'paper.plane'),
  _member(40, '고양이와나', 'me_and_cat'),
  _member(41, '별헤는밤', 'star_night', photo: true),
  _member(42, 'cocoa', 'cocoa_time'),
  _member(43, '취향수집가', 'taste.collector'),
  _member(44, '방구석여행', 'room_trip', photo: true),
  _member(45, 'Ocean Blue', 'ocean_blue'),
  _member(46, '딸기우유', 'strawberry_milk'),
  _member(47, '새벽감성', 'dawn.mood', photo: true),
  _member(48, 'Calm Down', 'calm_down'),
  _member(49, '꽃집사장', 'flower_shop'),
  _member(50, '반짝반짝', 'twinkle', photo: true),
  _member(51, 'Night Owl', 'night_owl'),

  // 방 OFF (목록·검색에서 빠져야 함)
  _member(52, '숨은방', 'hidden_room', roomOn: false),
  _member(53, '비공개', 'private_one', roomOn: false),
  _member(54, 'Cat Off', 'cat_off', roomOn: false),
  _member(55, '토글오프', 'toggle_off', roomOn: false),
];
