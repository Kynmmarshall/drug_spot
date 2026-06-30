class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.senderUsername,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ChatMessage(
      id: _readInt(json['id']),
      conversationId: _readInt(json['conversation']),
      sender: _readInt(sender),
      senderUsername: _readSenderUsername(json),
      text: json['text']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final int id;
  final int conversationId;
  final int sender;
  final String senderUsername;
  final String text;
  final bool isRead;
  final String createdAt;

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) return _readInt(value['id']);
    return 0;
  }

  static String _readSenderUsername(Map<String, dynamic> json) {
    final direct = json['sender_username'];
    if (direct != null) return direct.toString();

    final sender = json['sender'];
    if (sender is Map) {
      return (sender['username'] ?? sender['name'] ?? '').toString();
    }

    return '';
  }
}
