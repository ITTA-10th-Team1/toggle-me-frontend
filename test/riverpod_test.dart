import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/core/providers/app_providers.dart';

void main() {
  test('카운터 Provider 초기값은 0이다', () {
    final container = ProviderContainer.test();

    expect(container.read(appCounterProvider), 0);
  });

  test('카운터 Provider는 값을 증가시킬 수 있다', () {
    final container = ProviderContainer.test();

    container.read(appCounterProvider.notifier).increment();

    expect(container.read(appCounterProvider), 1);
  });

  test('카운터 Provider는 값을 초기화할 수 있다', () {
    final container = ProviderContainer.test();

    container.read(appCounterProvider.notifier).increment();
    container.read(appCounterProvider.notifier).reset();

    expect(container.read(appCounterProvider), 0);
  });
}
