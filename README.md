# toggle-me-frontend
[잇타 10기] Toggle, Me! 프론트엔드 레포지토리입니다.

## 프로젝트 소개

**Toggle me**는 사용자의 취향과 일상을 가상의 3D 공간에 기록하고 공유하는 라이프스타일 아카이빙 서비스입니다.

주요 기능:
- 3D 방 및 가구 표시
- 가구 선택 및 표시/숨김
- 가구별 이미지 및 아이템 아카이빙
- 로그인 및 사용자 인증
- 소셜 기능
- 방과 아이템의 공개 범위 설정

## 기술 스택

| 구분 | 기술 |
| --- | --- |
| 프레임워크 | Flutter |
| 언어 | Dart |
| 상태 관리 | Riverpod |
| 화면 이동 | go_router |
| 플랫폼 | Android, iOS |
| 버전 관리 | Git, GitHub |

※ Riverpod과 go_router는 팀에서 사용하기로 확정한 기술입니다. 실제 패키지 추가와 공통 설정은 별도 작업으로 진행합니다.

## 담당 기능

| 담당자 | 담당 영역 |
|---|---|
| 하은총 | 메인 방 및 3D |
| 황지희 | 아이템 |
| 이현재 | 소셜 및 로그인 |

※ 마이페이지 담당 및 세부 작업 분배는 추후 협의합니다.

## 개발 환경

- Flutter SDK 설치
- Dart SDK (Flutter에 포함)
- VS Code 또는 Android Studio
- Android Emulator 또는 실제 기기

## 시작하기

### 1. 저장소 복제

```bash
git clone https://github.com/ITTA-10th-Team1/toggle-me-frontend.git
cd toggle-me-frontend
```

### 2. 개발 환경 확인

```bash
flutter doctor
```

### 3. 패키지 설치

```bash
flutter pub get
```

### 4. 앱 실행

```bash
flutter run
```

## 프로젝트 구조

lib/
├── app/              # 앱 설정 및 테마
│   ├── app.dart
│   └── theme/
│       └── app_theme.dart
├── core/             # 공통 기능
│   ├── constants/
│   ├── network/
│   ├── utils/
│   └── widgets/
├── features/         # 기능별 코드
│   ├── room/         # 메인 방 및 3D
│   ├── item/         # 아이템
│   ├── auth/         # 로그인 및 인증
│   └── social/       # 소셜
└── main.dart         # 앱 진입점

assets/               # 이미지, 아이콘, 3D 모델
├── images/
├── icons/
└── models/

docs/                 # 개발 문서
└── CODE_CONVENTION.md

test/                 # 테스트 코드

## 협업 안내

기능 개발은 별도 브랜치에서 진행하고 Pull Request를 통해 병합합니다.

브랜치, 커밋, PR 및 코드 작성 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해 주세요.

## 관련 레포지토리

- [Frontend](https://github.com/ITTA-10th-Team1/toggle-me-frontend)
- [Backend](https://github.com/ITTA-10th-Team1/toggle-me-backend)

## 팀

ITTA 10기 1팀 - Toggle me
