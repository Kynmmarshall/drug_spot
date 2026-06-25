class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['last_message'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as int,
      participantIds: (json['participant_ids'] as List).cast<int>(),
      participantNames: (json['participant_names'] as List).cast<String>(),
      lastMessage: lastMsg != null ? LastMessage.fromJson(lastMsg) : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: json['updated_at'] as String,
    );
  }

  final int id;
  final List<int> participantIds;
  final List<String> participantNames;
  final LastMessage? lastMessage;
  final int unreadCount;
  final String updatedAt;

  String otherName(int myUserId) {
    final idx = participantIds.indexOf(myUserId);
    if (idx == -1 || participantNames.length < 2) {
      return participantNames.firstOrNull ?? 'Unknown';
    }
    return participantNames[idx == 0 ? 1 : 0];
  }
}

class LastMessage {
  const LastMessage({required this.text, required this.sender, required this.createdAt});

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text'] as String,
      sender: json['sender'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  final String text;
  final String sender;
  final String createdAt;
}
