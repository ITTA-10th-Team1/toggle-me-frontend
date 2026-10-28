import 'package:flutter_riverpod/flutter_riverpod.dart';

final appCounterProvider = NotifierProvider<AppCounterNotifier, int>(
  AppCounterNotifier.new,
);

class AppCounterNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }
}
