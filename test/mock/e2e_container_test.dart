@Timeout(Duration(seconds: 5))

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../core/signal_client_test.dart';
import '../mock/e2e_container.dart';

void main() {
  late E2EContainer container;
  late Room room;
  setUp(() async {
    container = E2EContainer();
    room = container.room;
  });

  tearDown(() async {
    await container.dispose();
  });

  test('connect', () async {
    await container.connectRoom();
    expect(room.connectionState, ConnectionState.connected);
    expect(room.localParticipant?.sid, joinResponse.join.participant.sid);
  });
}
