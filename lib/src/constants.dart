class Timeouts {
  final Duration connection;
  final Duration debounce;
  final Duration publish;
  final Duration peerConnection;
  final Duration iceRestart;

  const Timeouts({
    required this.connection,
    required this.debounce,
    required this.publish,
    required this.peerConnection,
    required this.iceRestart,
  });

  static const Timeouts defaultTimeouts = Timeouts(
    connection: Duration(seconds: 10),
    debounce: Duration(milliseconds: 100),
    publish: Duration(seconds: 10),
    peerConnection: Duration(seconds: 10),
    iceRestart: Duration(seconds: 10),
  );
}
