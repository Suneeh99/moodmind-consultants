class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  ChatMessage({required this.id, required this.senderId, required this.text, required this.timestamp});

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: (data['senderId'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      timestamp: (data['timestamp'] as dynamic)?.toDate(),
    );
  }
}
