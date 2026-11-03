# 공통 UI 사용 기준

## 이번 정리

| 목적 | 공통 파일 |
|---|---|
| 실제 색상 코드 정의 | lib/app/theme/app_colors.dart |
| 앱 기본 테마·ColorScheme | lib/app/theme/app_theme.dart |
| 온보딩 배경 그라데이션 | lib/app/theme/app_gradients.dart |
| 반복되는 버튼 글꼴 스타일 | lib/app/theme/app_text_styles.dart |
| ON/OFF 토글 | lib/core/widgets/room_mode_toggle.dart |
| 버튼·로딩·중복 클릭 방지 | lib/core/widgets/app_button.dart |
| 입력창·비밀번호 표시/숨김 | lib/core/widgets/app_text_field.dart |
| X로 닫는 짧은 안내 메시지 | lib/core/widgets/app_notice.dart |

토글은 기존 온보딩의 RoomModeToggle을 확장했고 메인 방의 별도 Switch도 이를 사용하도록 변경했습니다. 시각 크기는 60.86 × 36, 터치 영역은 높이 48입니다. 저장 중 로딩과 입력 차단, 접근성 상태, 키보드 조작을 지원합니다.

```dart
RoomModeToggle(
  isOn: isPublic,
  isLoading: isSaving,
  onChanged: changeVisibility,
)
```

기록 공개 설정에도 같은 UI를 사용할 수 있으며 semanticLabel만 해당 기능에 맞게 바꿀 수 있습니다. isOn은 외부에서 받아 표시하고 onChanged로 의도만 전달합니다. 방·기록의 API enum 변환, 저장 성공/실패 및 실제 상태 소유는 각 화면·서비스에 남깁니다. UI 부품 안에 로그인 상태나 API를 넣지 않습니다.

```dart
showAppNotice(context, '저장했어요.');
```

새 안내는 기존 메시지·대기열을 교체하며 X로 즉시 닫거나 2초 후 사라집니다. 중요한 확인·저장 실패 화면 전체를 이 안내로 대체하지 않습니다.

## 기존 팀원 코드 호환

- AuthColors는 없애지 않고 AppColors를 참조하는 호환 창구로 남겼습니다. 실제 색상 값은 AppColors 한 곳에서 정의합니다.
- 로그인 PrimaryButton은 기존 생성자 그대로 두고 AppButton을 사용합니다.
- 기존 auth/presentation/widgets/app_text_field.dart import도 공통 입력창을 export하므로 수정 없이 동작합니다.
- 공통 안내 함수는 로그인·방·라우터의 기존 안내에 적용했습니다. 기존 요청/라우팅 흐름은 바꾸지 않았습니다.
- 직접 작성한 TextStyle 중 반복되는 버튼 역할만 추출했습니다. 모든 화면의 모든 크기·여백을 하나로 강제하지 않습니다.

## 색상 관련 합의할 내용

현재 주황은 primary(#FF9638), roomAccent(#FF813B), authAccent(#F07B3F), guestAccent(#FF883F)로 달랐습니다. 먼저 같은 파일에 모으되 서로 다른 기존 색을 임의의 한 색으로 바꾸지는 않았습니다. 디자이너가 브랜드 팔레트를 확정하면 이 상수들을 한 값으로 연결할 수 있습니다. 동일한 값은 별칭으로 공유합니다.

폰트 파일·공식 글꼴 체계는 아직 제공되지 않아 임의의 새 폰트를 설치하거나 지정하지 않았습니다. 소셜 로그인 버튼, 3D 뷰어, 가구 배치 카드 같은 기능 전용 UI는 해당 feature 안에 유지합니다.

## 3D 카메라

설정은 room/presentation/room_camera_config.dart에 모았습니다. 카메라 방위각 45°, 극각 70°(수평선보다 약 20° 높은 시점), 시야각 6°를 사용합니다. 반경은 모델에 맞춰 105%로 계산합니다. 낮은 시점과 좁은 시야각으로 양 끝 벽의 세로선이 수직에 가까워지도록 합니다.

model-viewer는 원근 카메라이므로 정확한 정투영은 아닙니다. 완전히 평행한 수학적 정투영이 필수이면 렌더러 변경을 따로 검토해야 합니다. 이번에는 기존 가구 터치 연결과 자동 화면 맞춤을 유지하면서 약한 원근감으로 조정했습니다.

GLB 메시·가구 좌표·백엔드 전달 JSON은 변경하지 않습니다. 카메라만 변경했으므로 확정한 백엔드 좌표를 다시 보낼 필요는 없습니다. 최종 휴대폰 모습은 재실행 후 확인합니다.
