#!/usr/bin/env bash
set -euo pipefail

: "${API_BASE_URL:?Set API_BASE_URL in the Vercel project environment variables.}"

# Use the same Flutter release as the development environment.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
if [ ! -x .flutter-sdk/bin/flutter ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git .flutter-sdk
fi
export PATH="$PWD/.flutter-sdk/bin:$PATH"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter config --no-analytics
flutter pub get
flutter build web --release \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="KAKAO_JAVASCRIPT_APP_KEY=${KAKAO_JAVASCRIPT_APP_KEY:-}" \
  --dart-define="SHARE_LINK_URL=${SHARE_LINK_URL:-}"
