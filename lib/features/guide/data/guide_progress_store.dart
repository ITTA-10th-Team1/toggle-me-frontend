import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-account completion on this device. Kept independently of login tokens.
class GuideProgressStore {
  GuideProgressStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  String _key(int memberId) => 'usageGuide.v1.$memberId';

  Future<bool> hasCompleted(int memberId) async {
    try {
      return await _storage.read(key: _key(memberId)) == 'completed';
    } catch (_) {
      return false;
    }
  }

  Future<void> complete(int memberId) =>
      _storage.write(key: _key(memberId), value: 'completed');
}
