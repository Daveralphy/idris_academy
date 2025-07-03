class ChatMessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByUser;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByUser,
  });
}