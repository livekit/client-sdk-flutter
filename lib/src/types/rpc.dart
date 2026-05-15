import '../proto/livekit_models.pb.dart' as lk_models;

class PerformRpcParams {
  /// The unique participant identity of the destination.
  String destinationIdentity;

  /// The method name to call.
  String method;

  /// The payload of the request.
  String payload;

  /// Timeout for receiving a response after the initial connection (in milliseconds).
  /// If a value less than 8000 ms is provided, it will be automatically clamped to 8000 ms
  /// to ensure sufficient time for round-trip latency buffering.
  /// Default: 15000 ms.
  Duration responseTimeoutMs;

  PerformRpcParams({
    required this.destinationIdentity,
    required this.method,
    required this.payload,
    this.responseTimeoutMs = const Duration(milliseconds: 15000),
  });
}

class RpcInvocationData {
  /// The unique request ID. Will match at both sides of the call, useful for debugging or logging.
  String requestId;

  /// The unique participant identity of the caller.
  String callerIdentity;

  /// The payload of the request. User-definable format, typically JSON.
  String payload;

  /// The maximum time the caller will wait for a response.
  int responseTimeoutMs;

  RpcInvocationData({
    required this.requestId,
    required this.callerIdentity,
    required this.payload,
    required this.responseTimeoutMs,
  });
}

typedef RpcRequestHandler = Future<String> Function(RpcInvocationData data);

class RpcError implements Exception {
  final String message;
  final int code;
  final String? data;

  RpcError({
    required this.message,
    required this.code,
    this.data,
  });

  factory RpcError.fromProto(lk_models.RpcError error) {
    return RpcError(
      message: error.message,
      code: error.code,
      data: error.data,
    );
  }

  lk_models.RpcError toProto() {
    return lk_models.RpcError()
      ..message = message
      ..code = code
      ..data = data ?? '';
  }

  static final applicationError = 1500;
  static final connectionTimeout = 1501;
  static final responseTimeout = 1502;
  static final recipientDisconnected = 1503;
  static final responsePayloadTooLarge = 1504;
  static final sendFailed = 1505;

  static final unsupportedMethod = 1400;
  static final recipientNotFound = 1401;
  static final requestPayloadTooLarge = 1402;
  static final unsupportedServer = 1403;
  static final unsupportedVersion = 1404;

  static Map<int, String> errorMessages = {
    applicationError: 'Application error in method handler',
    connectionTimeout: 'Connection timeout',
    responseTimeout: 'Response timeout',
    recipientDisconnected: 'Recipient disconnected',
    responsePayloadTooLarge: 'Response payload too large',
    sendFailed: 'Failed to send',
    unsupportedMethod: 'Method not supported at destination',
    recipientNotFound: 'Recipient not found',
    requestPayloadTooLarge: 'Request payload too large',
    unsupportedServer: 'RPC not supported by server',
    unsupportedVersion: 'Unsupported RPC version',
  };

  /// Creates an error object from the code, with an auto-populated message.

  static RpcError builtIn(int errorCode, {String? data}) {
    return RpcError(
      message: errorMessages[errorCode] ?? 'Unknown error',
      code: errorCode,
      data: data,
    );
  }
}

/// Maximum payload size for RPC v1 requests and responses. When the remote participant
/// supports RPC v2 ([kClientProtocolDataStreamRpc] or higher), payloads of any size are
/// allowed because they are transported over data streams.
final kRpcMaxPayloadBytes = 15360; // 15 KB

/// RPC v1 wire version, sent in the `RpcRequest.version` packet field.
final int kRpcVesion = 1;

/// Client protocol versions advertised via `ParticipantInfo.clientProtocol`.
/// Spec name: `CLIENT_PROTOCOL_DEFAULT`. Indicates a peer that only supports RPC v1.
const int kClientProtocolDefault = 0;

/// Spec name: `CLIENT_PROTOCOL_DATA_STREAM_RPC`. Indicates a peer that supports RPC v2
/// (request/response payloads carried over text data streams).
const int kClientProtocolDataStreamRpc = 1;

const int kClientProtocol = kClientProtocolDataStreamRpc;

/// Data stream topic for RPC v2 requests.
const String kRpcRequestTopic = 'lk.rpc_request';

/// Data stream topic for RPC v2 success responses.
const String kRpcResponseTopic = 'lk.rpc_response';

/// Attribute keys used on RPC v2 request streams.
const String kRpcAttrRequestId = 'lk.rpc_request_id';
const String kRpcAttrMethod = 'lk.rpc_request_method';
const String kRpcAttrResponseTimeoutMs = 'lk.rpc_request_response_timeout_ms';
const String kRpcAttrVersion = 'lk.rpc_request_version';

/// Value sent in the `kRpcAttrVersion` attribute for v2 requests.
const String kRpcRequestVersionV2 = '2';
