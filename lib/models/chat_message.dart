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
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation'] as int? ?? 0,
      sender: json['sender'] as int,
      senderUsername: json['sender_username'] as String? ?? '',
      text: json['text'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final int conversationId;
  final int sender;
  final String senderUsername;
  final String text;
  final bool isRead;
  final String createdAt;
}
