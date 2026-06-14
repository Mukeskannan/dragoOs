class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser ? 1 : 0,
      'time': time.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      text: map['text'],
      isUser: map['isUser'] == 1,
      time: DateTime.parse(map['time']),
    );
  }
}