import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/utils.dart';

void main() {
  group('retry', () {
    // test if List of errors are thrown
    test(
      'throw all and throw error list',
      () => expect(
        Utils.retry<void>(
          (triesLeft, _) => throw 'error-${triesLeft}',
          tries: 3,
          delay: Duration.zero,
        ),
        throwsA([
          'error-2',
          'error-1',
          'error-0',
        ]),
      ),
    );
    test(
      'throw once and return result',
      () => expectLater(
        Utils.retry<String>(
          (triesLeft, _) async {
            expect(
              triesLeft,
              isNot(0),
              reason: 'should be never 0 because returning on 1',
            );
            if (triesLeft == 1) return 'result-${triesLeft}';
            throw 'error${triesLeft}';
          },
          tries: 3,
          delay: Duration.zero,
        ),
        completion('result-1'),
      ),
    );
  });
}
