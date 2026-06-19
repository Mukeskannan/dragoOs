class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;
  final int conversationId;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
    required this.conversationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser ? 1 : 0,
      'time': time.toIso8601String(),
      'conversation_id': conversationId,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      text: map['text'],
      isUser: map['isUser'] == 1,
      time: DateTime.parse(map['time']),
      conversationId: map['conversation_id'] ?? 1,
    );
  }
}