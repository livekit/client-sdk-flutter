/// Options when joining a room.
/// {@category Room}
class ConnectOptions {
  ///
  /// Auto-subscribe to room tracks upon connect, defaults to true.
  ///
  final bool autoSubscribe;

  ///
  ///
  ///
  final bool simulcast;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.simulcast = false,
  });
}
