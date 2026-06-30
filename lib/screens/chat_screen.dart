import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/context_extensions.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  final int conversationId;
  final String otherName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _started = false;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    debugPrint(
      '[ChatScreen] Starting conversationId=${widget.conversationId} '
      'otherName=${widget.otherName}',
    );
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connectWebSocket();
    });
  }

  Future<void> _loadHistory() async {
    try {
      debugPrint(
        '[ChatScreen] Loading history for conversationId=${widget.conversationId}',
      );
      final data = await context.appState.api.getMessages(
        widget.conversationId,
      );
      debugPrint('[ChatScreen] Loaded ${data.length} historical messages');
      if (!mounted) return;
      setState(() {
        _messages = data
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('[ChatScreen] Failed to load history: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _connectWebSocket() {
    if (!mounted) return;
    final api = context.appState.api;
    final token = api.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('[ChatScreen] Skipping websocket: missing access token');
      return;
    }

    final wsUrl =
        '${api.wsBaseUrl}/ws/chat/${widget.conversationId}/?token=$token';

    try {
      debugPrint(
        '[ChatScreen] Connecting websocket for conversationId=${widget.conversationId}',
      );
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(
        (data) {
          ChatMessage message;
          try {
            final decoded = jsonDecode(data as String);
            if (decoded is! Map<String, dynamic>) return;
            message = ChatMessage.fromJson({
              ...decoded,
              'conversation': decoded['conversation'] ?? widget.conversationId,
            });
          } catch (e) {
            debugPrint('[ChatScreen] Ignoring malformed websocket message: $e');
            return;
          }

          if (!mounted) return;
          debugPrint('[ChatScreen] Received websocket message id=${message.id}');
          _addMessage(message);
        },
        onError: (error) {
          debugPrint('[ChatScreen] Websocket error: $error');
          _channel = null;
        },
        onDone: () {
          debugPrint('[ChatScreen] Websocket closed');
          _channel = null;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[ChatScreen] Failed to connect websocket: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _sendMessageOverHttp(text);
  }

  void _addMessage(ChatMessage message) {
    final isDuplicate =
        message.id != 0 && _messages.any((m) => m.id == message.id);
    if (isDuplicate) return;

    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  Future<void> _sendMessageOverHttp(String text) async {
    try {
      debugPrint(
        '[ChatScreen] Sending message conversationId=${widget.conversationId}',
      );
      final json = await context.appState.api.sendMessage(
        widget.conversationId,
        text,
      );
      debugPrint('[ChatScreen] Sent message response: $json');
      if (!mounted) return;
      _addMessage(ChatMessage.fromJson(json));
    } catch (e, stackTrace) {
      debugPrint('[ChatScreen] Failed to send message: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = context.appState.api.userId ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.t('chat_start_hint'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      final isMine = msg.sender == myId;
                      return _MessageBubble(message: msg, isMine: isMine);
                    },
                  ),
          ),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMine ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: context.l10n.t('chat_hint'),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
