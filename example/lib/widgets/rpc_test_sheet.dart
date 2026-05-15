import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:livekit_client/livekit_client.dart';

class RpcInvocationRecord {
  final DateTime timestamp;
  final int byteLength;
  final String payload;
  final String callerIdentity;

  RpcInvocationRecord({
    required this.timestamp,
    required this.byteLength,
    required this.payload,
    required this.callerIdentity,
  });
}

class RpcHandlerEntry {
  final String topic;
  String staticResponse;
  final List<RpcInvocationRecord> invocations = [];

  RpcHandlerEntry({required this.topic, required this.staticResponse});
}

class RpcTestController extends ChangeNotifier {
  final List<RpcHandlerEntry> _handlers = [];
  Room? _room;

  List<RpcHandlerEntry> get handlers => List.unmodifiable(_handlers);

  bool isRegistered(String topic) => _handlers.any((h) => h.topic == topic);

  void registerHandler(Room room, String topic, String staticResponse) {
    if (isRegistered(topic)) {
      return;
    }
    _room = room;
    final entry = RpcHandlerEntry(topic: topic, staticResponse: staticResponse);
    _handlers.add(entry);
    room.registerRpcMethod(topic, (data) async {
      final bytes = utf8.encode(data.payload).length;
      entry.invocations.insert(
        0,
        RpcInvocationRecord(
          timestamp: DateTime.now(),
          byteLength: bytes,
          payload: data.payload,
          callerIdentity: data.callerIdentity,
        ),
      );
      notifyListeners();
      return entry.staticResponse;
    });
    notifyListeners();
  }

  void unregisterHandler(String topic) {
    final idx = _handlers.indexWhere((h) => h.topic == topic);
    if (idx < 0) {
      return;
    }
    _room?.unregisterRpcMethod(topic);
    _handlers.removeAt(idx);
    notifyListeners();
  }

  // Mutates the entry's response in place. The handler closure reads
  // entry.staticResponse fresh on each invocation, so no re-registration
  // is needed. Skip notifyListeners to avoid rebuild loops with the
  // editing TextField that drives this method.
  void updateStaticResponse(String topic, String response) {
    final entry = _handlers.firstWhere(
      (h) => h.topic == topic,
      orElse: () => throw StateError('topic $topic not registered'),
    );
    entry.staticResponse = response;
  }

  @override
  void dispose() {
    final room = _room;
    if (room != null) {
      for (final entry in _handlers) {
        room.unregisterRpcMethod(entry.topic);
      }
    }
    _handlers.clear();
    super.dispose();
  }
}

final Map<String, String Function()> _payloadPresets = {
  'hello': () => 'hello world',
  '20k': () => 'X' * 20000,
};

Future<void> showRpcTestSheet(
  BuildContext context,
  Room room,
  RpcTestController controller,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => RpcTestSheet(room: room, controller: controller),
    );

class RpcTestSheet extends StatefulWidget {
  final Room room;
  final RpcTestController controller;

  const RpcTestSheet({
    required this.room,
    required this.controller,
    super.key,
  });

  @override
  State<RpcTestSheet> createState() => _RpcTestSheetState();
}

class _RpcTestSheetState extends State<RpcTestSheet> {
  final _methodCtl = TextEditingController();
  final _payloadCtl = TextEditingController();
  final _handlerTopicCtl = TextEditingController();
  final _handlerResponseCtl = TextEditingController();

  String? _selectedIdentity;
  bool _isSending = false;
  _SendResult? _lastResult;

  @override
  void dispose() {
    _methodCtl.dispose();
    _payloadCtl.dispose();
    _handlerTopicCtl.dispose();
    _handlerResponseCtl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final identity = _selectedIdentity;
    final method = _methodCtl.text.trim();
    final local = widget.room.localParticipant;
    if (identity == null || method.isEmpty || local == null) {
      return;
    }
    final payload = _payloadCtl.text;
    setState(() {
      _isSending = true;
      _lastResult = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      final response = await local.performRpc(
        PerformRpcParams(
          destinationIdentity: identity,
          method: method,
          payload: payload,
        ),
      );
      stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastResult = _SendResult.success(response: response, elapsed: stopwatch.elapsed);
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastResult = _SendResult.error(error: e, elapsed: stopwatch.elapsed);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _register() {
    final topic = _handlerTopicCtl.text.trim();
    if (topic.isEmpty) {
      return;
    }
    if (widget.controller.isRegistered(topic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Handler for "$topic" is already registered')),
      );
      return;
    }
    widget.controller.registerHandler(widget.room, topic, _handlerResponseCtl.text);
    _handlerTopicCtl.clear();
  }

  void _applyPreset(String preset, TextEditingController target) {
    final fn = _payloadPresets[preset];
    if (fn == null) {
      return;
    }
    target.text = fn();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _buildSendSection(theme),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildHandlersSection(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Row(
          children: [
            Text('RPC Tester', style: theme.textTheme.titleLarge),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

  Widget _buildSendSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send RPC', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: widget.room,
            builder: (context, _) {
              final remotes = widget.room.remoteParticipants.values.toList();
              final identities = remotes.map((p) => p.identity).toList();
              final currentValue = identities.contains(_selectedIdentity) ? _selectedIdentity : null;
              return DropdownButtonFormField<String>(
                initialValue: currentValue,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                hint: Text(remotes.isEmpty ? 'no other participants' : 'select participant'),
                items: remotes
                    .map((p) => DropdownMenuItem<String>(
                          value: p.identity,
                          child: Text(
                            p.name.isNotEmpty ? '${p.name} (${p.identity})' : p.identity,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: remotes.isEmpty
                    ? null
                    : (value) => setState(() {
                          _selectedIdentity = value;
                        }),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _methodCtl,
            decoration: const InputDecoration(
              labelText: 'Method',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payloadCtl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Payload',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ..._payloadPresets.keys.map(
                (preset) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _applyPreset(preset, _payloadCtl),
                    child: Text(preset),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _canSend() ? () => unawaited(_send()) : null,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Sending…' : 'Send'),
              ),
            ],
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            _ResultPanel(result: _lastResult!),
          ],
        ],
      );

  bool _canSend() =>
      !_isSending &&
      _selectedIdentity != null &&
      _methodCtl.text.trim().isNotEmpty &&
      widget.room.localParticipant != null;

  Widget _buildHandlersSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Handlers', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _handlerTopicCtl,
            decoration: const InputDecoration(
              labelText: 'Topic',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _handlerResponseCtl,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Static response',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ..._payloadPresets.keys.map(
                (preset) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _applyPreset(preset, _handlerResponseCtl),
                    child: Text(preset),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _register,
                icon: const Icon(Icons.add),
                label: const Text('Register'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final handlers = widget.controller.handlers;
              if (handlers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'no handlers registered',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                    ),
                  ),
                );
              }
              return Column(
                children: handlers
                    .map((e) => _HandlerCard(
                          key: ValueKey(e.topic),
                          entry: e,
                          controller: widget.controller,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      );
}

class _HandlerCard extends StatefulWidget {
  final RpcHandlerEntry entry;
  final RpcTestController controller;

  const _HandlerCard({required this.entry, required this.controller, super.key});

  @override
  State<_HandlerCard> createState() => _HandlerCardState();
}

class _HandlerCardState extends State<_HandlerCard> {
  late final TextEditingController _responseCtl;

  @override
  void initState() {
    super.initState();
    _responseCtl = TextEditingController(text: widget.entry.staticResponse);
  }

  @override
  void dispose() {
    _responseCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.topic,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.scaffoldBackgroundColor),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Unregister'),
                  onPressed: () => widget.controller.unregisterHandler(entry.topic),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _responseCtl,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Static response',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => widget.controller.updateStaticResponse(entry.topic, value),
              style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._payloadPresets.keys.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        final fn = _payloadPresets[preset];
                        if (fn == null) return;
                        final value = fn();
                        _responseCtl.text = value;
                        widget.controller.updateStaticResponse(entry.topic, value);
                      },
                      child: Text(
                        preset,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.cardColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Invocations (${entry.invocations.length})',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 200,
              child: entry.invocations.isEmpty
                  ? Center(
                      child: Text(
                        'waiting…',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entry.invocations.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, i) => _InvocationRow(record: entry.invocations[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvocationRow extends StatelessWidget {
  final RpcInvocationRecord record;

  const _InvocationRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_formatTimestamp(record.timestamp)}   ${record.byteLength}B   from ${record.callerIdentity}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 2),
        SelectableText(
          record.payload,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          maxLines: 4,
          minLines: 1,
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final _SendResult result;

  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = result.isSuccess;
    final color = isSuccess ? Colors.green : Colors.red;
    final title = isSuccess
        ? 'Response  (${utf8.encode(result.response!).length}B, ${result.elapsed.inMilliseconds}ms)'
        : _errorTitle(result.error!, result.elapsed);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SelectableText(
            isSuccess ? result.response! : _errorBody(result.error!),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _errorTitle(Object e, Duration elapsed) {
    if (e is RpcError) {
      return 'RpcError ${e.code}  (${elapsed.inMilliseconds}ms)';
    }
    return 'Error  (${elapsed.inMilliseconds}ms)';
  }

  static String _errorBody(Object e) {
    if (e is RpcError) {
      final data = e.data;
      final dataLine = (data != null && data.isNotEmpty) ? '\ndata: $data' : '';
      return '${e.message}$dataLine';
    }
    return e.toString();
  }
}

class _SendResult {
  final String? response;
  final Object? error;
  final Duration elapsed;
  final bool isSuccess;

  _SendResult.success({required String this.response, required this.elapsed})
      : error = null,
        isSuccess = true;

  _SendResult.error({required Object this.error, required this.elapsed})
      : response = null,
        isSuccess = false;
}

String _formatTimestamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  String three(int n) => n.toString().padLeft(3, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
}
