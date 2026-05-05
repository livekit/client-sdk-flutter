import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

class ExampleRoomMessage {
  const ExampleRoomMessage({
    required this.id,
    required this.text,
    required this.senderIdentity,
    required this.createdAt,
    this.isLocal = false,
    this.isSystem = false,
  });

  factory ExampleRoomMessage.chat({
    required String text,
    required String senderIdentity,
    required bool isLocal,
  }) {
    final now = DateTime.now();
    return ExampleRoomMessage(
      id: '${now.microsecondsSinceEpoch}-$senderIdentity',
      text: text,
      senderIdentity: senderIdentity,
      createdAt: now,
      isLocal: isLocal,
    );
  }

  factory ExampleRoomMessage.system(String text) {
    final now = DateTime.now();
    return ExampleRoomMessage(
      id: '${now.microsecondsSinceEpoch}-system',
      text: text,
      senderIdentity: 'system',
      createdAt: now,
      isSystem: true,
    );
  }

  factory ExampleRoomMessage.fromJson(Map<String, dynamic> json) => ExampleRoomMessage(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: json['text'] as String? ?? '',
        senderIdentity: json['senderIdentity'] as String? ?? 'unknown',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final String text;
  final String senderIdentity;
  final DateTime createdAt;
  final bool isLocal;
  final bool isSystem;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'senderIdentity': senderIdentity,
        'createdAt': createdAt.toIso8601String(),
      };
}

class MessagesPanel extends StatefulWidget {
  const MessagesPanel({
    required this.messages,
    required this.controller,
    required this.onSend,
    this.onClose,
    super.key,
  });

  final List<ExampleRoomMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onClose;

  @override
  State<MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends State<MessagesPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant MessagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: LKColors.surface,
          border: Border.all(color: LKColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble, size: 18, color: LKColors.lkBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${widget.messages.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: LKColors.textSecondary,
                        ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      tooltip: 'Close messages',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onClose,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: LKColors.border),
            Expanded(
              child: widget.messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LKColors.textSecondary,
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: widget.messages[index]),
                    ),
            ),
            const Divider(height: 1, color: LKColors.border),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => widget.onSend(),
                      decoration: const InputDecoration(
                        hintText: 'Send a room message',
                        filled: true,
                        fillColor: LKColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: LKColors.border),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: LKColors.border),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: LKColors.lkBlue),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.send),
                    onPressed: widget.onSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ExampleRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isLocal ? Alignment.centerRight : Alignment.centerLeft;
    final background = message.isSystem
        ? LKColors.surfaceAlt
        : message.isLocal
            ? LKColors.lkBlue
            : LKColors.lkGray3;
    final foreground = message.isLocal ? Colors.white : LKColors.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: message.isLocal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isSystem)
              Text(
                message.senderIdentity,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            Text(
              message.text,
              softWrap: true,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
