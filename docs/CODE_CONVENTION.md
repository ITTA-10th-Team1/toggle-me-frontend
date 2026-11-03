# Toggle me - Flutter 코드 컨벤션

※ 아래 규칙은 초기 제안안이며 팀원 협의 후 확정합니다.

## 1. 네이밍 규칙

| 대상 | 규칙 | 예시 |
|---|---|---|
| Dart 파일 | snake_case | room_screen.dart |
| 클래스 | PascalCase | RoomScreen |
| 변수 및 함수 | camelCase | selectedItem, loadItems() |
| 상수 | lowerCamelCase | defaultPadding |
| 비공개 멤버 | 언더스코어 접두사 | _loadData() |

## 2. 이미지 네이밍 규칙

이미지 파일은 해당 이미지를 사용하는 페이지를 기준으로 이름을 작성합니다.

- **형식**: `img_페이지명_설명`
- **작성 규칙**: 소문자와 snake_case 사용
- **공통으로 사용하는 이미지**는 페이지명 대신 `common` 사용

**예시**

| 파일명 | 설명 |
|---|---|
| `img_login_logo.png` | 로그인 페이지 로고 |
| `img_onboarding_room.png` | 온보딩 페이지 방 이미지 |
| `img_home_empty.png` | 홈 페이지 빈 화면 이미지 |
| `img_item_placeholder.png` | 아이템 페이지 기본 이미지 |
| `img_common_background.png` | 여러 페이지에서 공통으로 사용하는 배경 이미지 |

이미지 파일명만으로 사용 목적과 위치를 쉽게 파악할 수 있도록 작성합니다.

## 3. 폴더 구조

- lib/app: 앱 설정, 라우팅, 테마
- lib/core: 공통 위젯, 상수, 네트워크, 유틸리티
- lib/features: 기능별 코드
- assets: 이미지, 아이콘, 3D 모델

## 4. 위젯 작성 규칙

- 가능한 경우 const 생성자를 사용합니다.
- 하나의 위젯에 지나치게 많은 기능을 넣지 않습니다.
- 반복적으로 사용하는 UI는 공통 위젯으로 분리합니다.
- UI와 데이터 처리 로직을 가능한 한 분리합니다.
- 간단한 화면 내부 상태는 setState를 사용할 수 있습니다.

## 5. 상태 관리

- Riverpod 도입 제안 중
- 여러 화면에서 공유하는 상태는 합의된 방식을 사용합니다.
- 단순한 화면 내부 상태는 setState 사용을 허용합니다.

## 6. 화면 이동

- go_router 도입 제안 중
- 화면 경로는 공통 라우터에서 관리하는 방식을 권장합니다.
- 최종 결정 후 구체적인 사용 규칙을 추가합니다.

## 7. 코드 품질

코드 제출 전 다음 명령어를 실행합니다.

    dart format .
    flutter analyze
    flutter test

- 분석 오류가 발생하면 수정합니다.
- 사용하지 않는 import 및 변수는 제거합니다.
- 디버깅용 출력문은 정리합니다.
- 중요한 기능은 가능한 범위에서 테스트 코드를 작성합니다.
