import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/pages/connection_check.dart';
import 'package:livekit_example/pages/prejoin.dart';
import 'package:livekit_example/theme.dart';
import 'package:livekit_example/widgets/text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../exts.dart';

enum _ConnectOption { autoSubscribe, e2ee, tokenServer }

enum _RoomOption { simulcast, adaptiveStream, dynacast, multiCodec }

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  static const _storeKeyUri = 'uri';
  static const _storeKeyToken = 'token';
  static const _storeKeySimulcast = 'simulcast';
  static const _storeKeyAdaptiveStream = 'adaptive-stream';
  static const _storeKeyDynacast = 'dynacast';
  static const _storeKeyE2EE = 'e2ee';
  static const _storeKeySharedKey = 'shared-key';
  static const _storeKeyMultiCodec = 'multi-codec';
  static const _storeKeyPreferredCodec = 'preferred-codec';
  static const _storeKeyAutoSubscribe = 'auto-subscribe';
  static const _storeKeyTokenServer = 'token-server';
  static const _storeKeyRoomName = 'room-name';
  static const _storeKeyConnectionHistory = 'connection-history';
  static const _codecOptions = ['AV1', 'VP9', 'VP8', 'H264', 'H265'];

  final _uriCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _roomNameCtrl = TextEditingController();
  final _sharedKeyCtrl = TextEditingController();

  bool _simulcast = true;
  bool _adaptiveStream = true;
  bool _dynacast = true;
  bool _autoSubscribe = true;
  bool _useTokenServer = false;
  bool _busy = false;
  bool _e2ee = false;
  bool _multiCodec = false;
  String _preferredCodec = 'VP8';
  List<_ConnectionHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    unawaited(_readPrefs());
    if (lkPlatformIs(PlatformType.android)) {
      unawaited(_checkPermissions());
    }
  }

  @override
  void dispose() {
    _uriCtrl.dispose();
    _tokenCtrl.dispose();
    _roomNameCtrl.dispose();
    _sharedKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Permission disabled');
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Connect Permission disabled');
    }

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      print('Camera Permission disabled');
    }

    status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      print('Microphone Permission disabled');
    }
  }

  Future<void> _readPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getString(_storeKeyConnectionHistory);

    _uriCtrl.text =
        const bool.hasEnvironment('URL') ? const String.fromEnvironment('URL') : prefs.getString(_storeKeyUri) ?? '';
    _tokenCtrl.text = const bool.hasEnvironment('TOKEN')
        ? const String.fromEnvironment('TOKEN')
        : prefs.getString(_storeKeyToken) ?? '';
    _sharedKeyCtrl.text = const bool.hasEnvironment('E2EEKEY')
        ? const String.fromEnvironment('E2EEKEY')
        : prefs.getString(_storeKeySharedKey) ?? '';
    _roomNameCtrl.text = const bool.hasEnvironment('ROOM')
        ? const String.fromEnvironment('ROOM')
        : prefs.getString(_storeKeyRoomName) ?? '';

    if (!mounted) return;
    setState(() {
      _simulcast = prefs.getBool(_storeKeySimulcast) ?? true;
      _adaptiveStream = prefs.getBool(_storeKeyAdaptiveStream) ?? true;
      _dynacast = prefs.getBool(_storeKeyDynacast) ?? true;
      _autoSubscribe = prefs.getBool(_storeKeyAutoSubscribe) ?? true;
      _useTokenServer = prefs.getBool(_storeKeyTokenServer) ?? false;
      _e2ee = prefs.getBool(_storeKeyE2EE) ?? false;
      _multiCodec = prefs.getBool(_storeKeyMultiCodec) ?? false;
      _preferredCodec = prefs.getString(_storeKeyPreferredCodec) ?? 'VP8';
      _history = _ConnectionHistoryEntry.decodeList(savedHistory);
    });
  }

  Future<void> _writePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKeyUri, _uriCtrl.text);
    await prefs.setString(_storeKeyToken, _tokenCtrl.text);
    await prefs.setString(_storeKeyRoomName, _roomNameCtrl.text);
    await prefs.setString(_storeKeySharedKey, _sharedKeyCtrl.text);
    await prefs.setBool(_storeKeySimulcast, _simulcast);
    await prefs.setBool(_storeKeyAdaptiveStream, _adaptiveStream);
    await prefs.setBool(_storeKeyDynacast, _dynacast);
    await prefs.setBool(_storeKeyAutoSubscribe, _autoSubscribe);
    await prefs.setBool(_storeKeyTokenServer, _useTokenServer);
    await prefs.setBool(_storeKeyE2EE, _e2ee);
    await prefs.setBool(_storeKeyMultiCodec, _multiCodec);
    await prefs.setString(_storeKeyPreferredCodec, _preferredCodec);
  }

  Future<void> _writeHistory(List<_ConnectionHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storeKeyConnectionHistory,
      _ConnectionHistoryEntry.encodeList(history),
    );
  }

  Future<TokenSourceResponse> _resolveCredentials() async {
    final url = _uriCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (!_useTokenServer) {
      return TokenSourceResponse(serverUrl: url, participantToken: token);
    }
    if (url.isEmpty) {
      throw Exception('Enter a token server URL (e.g. https://example.com/api/token) or a development token server ID');
    }
    final roomName = _roomNameCtrl.text.trim();
    final options = TokenRequestOptions(roomName: roomName.isEmpty ? null : roomName);
    return _tokenSourceFor(url).fetch(options);
  }

  static const _sandboxHostSuffix = '.sandbox.livekit.io';

  static TokenSourceConfigurable _tokenSourceFor(String input) {
    if (RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$').hasMatch(input)) {
      return DevelopmentTokenSource(id: input);
    }

    final uri = Uri.tryParse(input);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw Exception('Enter a valid token server URL (e.g. https://example.com/api/token)');
    }
    if (!['http', 'https'].contains(uri.scheme)) {
      throw Exception('Token server URL must use http or https (got ${uri.scheme}://)');
    }

    final host = uri.host.toLowerCase();
    if (host.endsWith(_sandboxHostSuffix) && (uri.path.isEmpty || uri.path == '/')) {
      final id = host.substring(0, host.length - _sandboxHostSuffix.length);
      if (id.isNotEmpty) return DevelopmentTokenSource(id: id);
    }

    return EndpointTokenSource(url: uri);
  }

  Future<void> _connect(BuildContext ctx) async {
    try {
      setState(() {
        _busy = true;
      });

      await _writePrefs();
      await _saveCurrentConnectionToHistory();

      final credentials = await _resolveCredentials();
      final url = credentials.serverUrl;
      final token = credentials.participantToken;
      final e2eeKey = _sharedKeyCtrl.text;
      if (!ctx.mounted) return;
      await Navigator.push<void>(
        ctx,
        MaterialPageRoute(
          builder: (_) => PreJoinPage(
            args: JoinArgs(
              url: url,
              token: token,
              e2ee: _e2ee,
              e2eeKey: e2eeKey,
              simulcast: _simulcast,
              adaptiveStream: _adaptiveStream,
              dynacast: _dynacast,
              autoSubscribe: _autoSubscribe,
              preferredCodec: _multiCodec ? _preferredCodec : 'VP8',
              enableBackupVideoCodec: _multiCodec && ['VP9', 'AV1'].contains(_preferredCodec),
            ),
          ),
        ),
      );
    } catch (error) {
      print('Could not connect $error');
      if (!ctx.mounted) return;
      await ctx.showErrorDialog(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _connectionCheck(BuildContext ctx) async {
    // Save URL and Token for convenience
    await _writePrefs();
    final TokenSourceResponse credentials;
    try {
      credentials = await _resolveCredentials();
    } catch (error) {
      print('Could not resolve credentials $error');
      if (!ctx.mounted) return;
      await ctx.showErrorDialog(error);
      return;
    }
    if (!ctx.mounted) return;
    await Navigator.push<void>(
      ctx,
      MaterialPageRoute(
          builder: (_) => ConnectionCheckPage(
                url: credentials.serverUrl,
                token: credentials.participantToken,
              )),
    );
  }

  Future<void> _saveCurrentConnectionToHistory() async {
    final entry = _ConnectionHistoryEntry(
      url: _uriCtrl.text.trim(),
      token: _tokenCtrl.text.trim(),
      roomName: _roomNameCtrl.text.trim(),
      e2ee: _e2ee,
      e2eeKey: _sharedKeyCtrl.text,
      simulcast: _simulcast,
      adaptiveStream: _adaptiveStream,
      dynacast: _dynacast,
      autoSubscribe: _autoSubscribe,
      useTokenServer: _useTokenServer,
      multiCodec: _multiCodec,
      preferredCodec: _preferredCodec,
      updatedAt: DateTime.now(),
    );
    if (entry.url.isEmpty && entry.token.isEmpty) return;

    final next = [
      entry,
      ..._history.where(
        (item) => item.url != entry.url || item.token != entry.token,
      ),
    ].take(5).toList();

    setState(() {
      _history = next;
    });
    await _writeHistory(next);
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history = [];
    });
    await _writeHistory(const []);
  }

  void _applyHistory(_ConnectionHistoryEntry entry) {
    _uriCtrl.text = entry.url;
    _tokenCtrl.text = entry.token;
    _roomNameCtrl.text = entry.roomName;
    _sharedKeyCtrl.text = entry.e2eeKey;
    setState(() {
      _e2ee = entry.e2ee;
      _simulcast = entry.simulcast;
      _adaptiveStream = entry.adaptiveStream;
      _dynacast = entry.dynacast;
      _autoSubscribe = entry.autoSubscribe;
      _useTokenServer = entry.useTokenServer;
      _multiCodec = entry.multiCodec;
      _preferredCodec = entry.preferredCodec;
    });
  }

  void _handleConnectOption(_ConnectOption option) {
    setState(() {
      if (option == _ConnectOption.autoSubscribe) {
        _autoSubscribe = !_autoSubscribe;
      } else if (option == _ConnectOption.e2ee) {
        _e2ee = !_e2ee;
      } else if (option == _ConnectOption.tokenServer) {
        _useTokenServer = !_useTokenServer;
      }
    });
    unawaited(_writePrefs());
  }

  void _handleRoomOption(Object option) {
    setState(() {
      if (option == _RoomOption.simulcast) {
        _simulcast = !_simulcast;
      } else if (option == _RoomOption.adaptiveStream) {
        _adaptiveStream = !_adaptiveStream;
      } else if (option == _RoomOption.dynacast) {
        _dynacast = !_dynacast;
      } else if (option == _RoomOption.multiCodec) {
        _multiCodec = !_multiCodec;
      } else if (option is String) {
        _preferredCodec = option;
      }
    });
    unawaited(_writePrefs());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 48 : 20,
                  vertical: wide ? 48 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _ConnectIntro()),
                              const SizedBox(width: 56),
                              SizedBox(
                                width: 430,
                                child: _buildConnectSurface(context),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _ConnectIntro(),
                              const SizedBox(height: 32),
                              _buildConnectSurface(context),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildConnectSurface(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LKColors.surface,
          border: Border.all(color: LKColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect to a room',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            LKTextField(
              label: _useTokenServer ? 'Token Server URL' : 'Server URL',
              ctrl: _uriCtrl,
              icon: _useTokenServer ? Icons.cloud : Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 18),
            if (_useTokenServer)
              LKTextField(
                label: 'Room Name',
                ctrl: _roomNameCtrl,
                icon: Icons.meeting_room,
              )
            else
              LKTextField(
                label: 'Token',
                ctrl: _tokenCtrl,
                icon: Icons.key,
                obscureText: true,
              ),
            const SizedBox(height: 18),
            LKTextField(
              label: 'E2EE Key',
              ctrl: _sharedKeyCtrl,
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ConnectOptionsMenu(
                  autoSubscribe: _autoSubscribe,
                  e2ee: _e2ee,
                  tokenServer: _useTokenServer,
                  onSelected: _handleConnectOption,
                ),
                _RoomOptionsMenu(
                  simulcast: _simulcast,
                  adaptiveStream: _adaptiveStream,
                  dynacast: _dynacast,
                  multiCodec: _multiCodec,
                  preferredCodec: _preferredCodec,
                  codecOptions: _codecOptions,
                  onSelected: _handleRoomOption,
                ),
                if (_history.isNotEmpty)
                  _RecentConnectionsMenu(
                    history: _history,
                    onSelected: (entry) {
                      _applyHistory(entry);
                      unawaited(_connect(context));
                    },
                    onClear: () => unawaited(_clearHistory()),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _connect(context),
              icon: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.bolt),
              label: Text(_busy ? 'CONNECTING' : 'CONNECT'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => unawaited(_connectionCheck(context)),
              child: const Text('Connection Check'),
            ),
          ],
        ),
      );
}

class _ConnectIntro extends StatelessWidget {
  const _ConnectIntro();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('images/logo-dark.svg', width: 210),
          const SizedBox(height: 24),
          Text(
            'Flutter SDK example',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'SDK Version ${LiveKitClient.version}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: LKColors.textSecondary),
          ),
        ],
      );
}

class _ConnectOptionsMenu extends StatelessWidget {
  const _ConnectOptionsMenu({
    required this.autoSubscribe,
    required this.e2ee,
    required this.tokenServer,
    required this.onSelected,
  });

  final bool autoSubscribe;
  final bool e2ee;
  final bool tokenServer;
  final ValueChanged<_ConnectOption> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ConnectOption>(
        tooltip: 'Connect options',
        onSelected: onSelected,
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: _ConnectOption.autoSubscribe,
            checked: autoSubscribe,
            child: const Text('Auto-subscribe'),
          ),
          CheckedPopupMenuItem(
            value: _ConnectOption.e2ee,
            checked: e2ee,
            child: const Text('Enable E2EE'),
          ),
          CheckedPopupMenuItem(
            value: _ConnectOption.tokenServer,
            checked: tokenServer,
            child: const Text('Server URL is token server'),
          ),
        ],
        child: const _MenuButton(icon: Icons.bolt, label: 'Connect Options'),
      );
}

class _RoomOptionsMenu extends StatelessWidget {
  const _RoomOptionsMenu({
    required this.simulcast,
    required this.adaptiveStream,
    required this.dynacast,
    required this.multiCodec,
    required this.preferredCodec,
    required this.codecOptions,
    required this.onSelected,
  });

  final bool simulcast;
  final bool adaptiveStream;
  final bool dynacast;
  final bool multiCodec;
  final String preferredCodec;
  final List<String> codecOptions;
  final ValueChanged<Object> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Object>(
        tooltip: 'Room options',
        onSelected: onSelected,
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: _RoomOption.simulcast,
            checked: simulcast,
            child: const Text('Simulcast'),
          ),
          CheckedPopupMenuItem(
            value: _RoomOption.adaptiveStream,
            checked: adaptiveStream,
            child: const Text('Adaptive stream'),
          ),
          CheckedPopupMenuItem(
            value: _RoomOption.dynacast,
            checked: dynacast,
            child: const Text('Dynacast'),
          ),
          CheckedPopupMenuItem(
            value: _RoomOption.multiCodec,
            checked: multiCodec,
            child: const Text('Multi-codec publish'),
          ),
          if (multiCodec) const PopupMenuDivider(),
          if (multiCodec)
            ...codecOptions.map(
              (codec) => CheckedPopupMenuItem(
                value: codec,
                checked: preferredCodec == codec,
                child: Text('Preferred codec: $codec'),
              ),
            ),
        ],
        child: const _MenuButton(icon: Icons.tune, label: 'Room Options'),
      );
}

class _RecentConnectionsMenu extends StatelessWidget {
  const _RecentConnectionsMenu({
    required this.history,
    required this.onSelected,
    required this.onClear,
  });

  final List<_ConnectionHistoryEntry> history;
  final ValueChanged<_ConnectionHistoryEntry> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Object>(
        tooltip: 'Recent connections',
        onSelected: (value) {
          if (value == _RecentMenuAction.clear) {
            onClear();
          } else if (value is _ConnectionHistoryEntry) {
            onSelected(value);
          }
        },
        itemBuilder: (context) => [
          ...history.map(
            (entry) => PopupMenuItem<Object>(
              value: entry,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(entry.displayTitle, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  entry.displaySubtitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<Object>(
            value: _RecentMenuAction.clear,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.clear),
              title: Text('Clear history'),
            ),
          ),
        ],
        child: const _MenuButton(icon: Icons.history, label: 'Recent'),
      );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: LKColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: LKColors.lkGreen),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: LKColors.textSecondary),
          ],
        ),
      );
}

enum _RecentMenuAction { clear }

class _ConnectionHistoryEntry {
  const _ConnectionHistoryEntry({
    required this.url,
    required this.token,
    this.roomName = '',
    required this.e2ee,
    required this.e2eeKey,
    required this.simulcast,
    required this.adaptiveStream,
    required this.dynacast,
    required this.autoSubscribe,
    this.useTokenServer = false,
    required this.multiCodec,
    required this.preferredCodec,
    required this.updatedAt,
  });

  factory _ConnectionHistoryEntry.fromJson(Map<String, dynamic> json) => _ConnectionHistoryEntry(
        url: json['url'] as String? ?? '',
        token: json['token'] as String? ?? '',
        roomName: json['roomName'] as String? ?? '',
        e2ee: json['e2ee'] as bool? ?? false,
        e2eeKey: json['e2eeKey'] as String? ?? '',
        simulcast: json['simulcast'] as bool? ?? true,
        adaptiveStream: json['adaptiveStream'] as bool? ?? true,
        dynacast: json['dynacast'] as bool? ?? true,
        autoSubscribe: json['autoSubscribe'] as bool? ?? true,
        useTokenServer: json['useTokenServer'] as bool? ?? false,
        multiCodec: json['multiCodec'] as bool? ?? false,
        preferredCodec: json['preferredCodec'] as String? ?? 'VP8',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  final String url;
  final String token;
  final String roomName;
  final bool e2ee;
  final String e2eeKey;
  final bool simulcast;
  final bool adaptiveStream;
  final bool dynacast;
  final bool autoSubscribe;
  final bool useTokenServer;
  final bool multiCodec;
  final String preferredCodec;
  final DateTime updatedAt;

  String get displayTitle {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url.isEmpty ? 'Untitled room' : url;
    }
    return uri.host;
  }

  String get displaySubtitle {
    final options = [
      if (useTokenServer) roomName.isEmpty ? 'token server' : 'token server / $roomName',
      if (e2ee) 'E2EE',
      if (autoSubscribe) 'auto-subscribe',
      if (multiCodec) preferredCodec,
    ];
    return options.isEmpty ? 'Saved connection' : options.join(' / ');
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'token': token,
        'roomName': roomName,
        'e2ee': e2ee,
        'e2eeKey': e2eeKey,
        'simulcast': simulcast,
        'adaptiveStream': adaptiveStream,
        'dynacast': dynacast,
        'autoSubscribe': autoSubscribe,
        'useTokenServer': useTokenServer,
        'multiCodec': multiCodec,
        'preferredCodec': preferredCodec,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static List<_ConnectionHistoryEntry> decodeList(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final data = jsonDecode(encoded) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(_ConnectionHistoryEntry.fromJson)
          .where((entry) => entry.url.isNotEmpty || entry.token.isNotEmpty)
          .toList();
    } catch (error) {
      print('Failed to decode connection history: $error');
      return [];
    }
  }

  static String encodeList(List<_ConnectionHistoryEntry> entries) =>
      jsonEncode(entries.map((entry) => entry.toJson()).toList());
}
