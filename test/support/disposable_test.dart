import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/support/disposable.dart';

class TestDisposable extends Disposable {
  @override
  Future<bool> dispose() async {
    return await super.dispose();
  }
}

void main() {
  group('Disposable', () {
    test('should execute all dispose functions even if one fails', () async {
      final disposable = TestDisposable();
      bool func1Called = false;
      bool func2Called = false;
      bool func3Called = false;

      // Dispose functions are called in reverse order of addition

      // Added 1st -> Called 3rd
      disposable.onDispose(() async {
        func1Called = true;
      });

      // Added 2nd -> Called 2nd
      disposable.onDispose(() async {
        func2Called = true;
        throw Exception('fail');
      });

      // Added 3rd -> Called 1st
      disposable.onDispose(() async {
        func3Called = true;
      });

      await disposable.dispose();

      expect(func3Called, isTrue, reason: 'Last added (func3) should be called first');
      expect(func2Called, isTrue, reason: 'Middle added (func2) should be called');
      expect(func1Called, isTrue, reason: 'First added (func1) should be called even if func2 failed');
    });
  });
}
