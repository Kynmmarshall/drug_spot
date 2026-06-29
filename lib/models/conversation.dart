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
    final lastMsg = json['last_message'];
    return Conversation(
      id: _readInt(json['id']),
      participantIds: _readIntList(json['participant_ids']),
      participantNames: _readStringList(json['participant_names']),
      lastMessage: lastMsg is Map<String, dynamic>
          ? LastMessage.fromJson(lastMsg)
          : null,
      unreadCount: _readInt(json['unread_count']),
      updatedAt: json['updated_at']?.toString() ?? '',
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

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) return _readInt(value['id']);
    return 0;
  }

  static List<int> _readIntList(Object? value) {
    if (value is! List) return const [];
    return value.map(_readInt).where((id) => id != 0).toList();
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) {
      if (item is Map) {
        return (item['username'] ?? item['name'] ?? item['id'] ?? 'Unknown')
            .toString();
      }
      return item.toString();
    }).toList();
  }
}

class LastMessage {
  const LastMessage({
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text']?.toString() ?? '',
      sender: json['sender']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final String text;
  final String sender;
  final String createdAt;
}
