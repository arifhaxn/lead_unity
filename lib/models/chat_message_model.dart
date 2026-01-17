class ChatMessage {
  final String id;
  final String content;
  final String sender; // 'user' or 'assistant'
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  // Factory constructor to create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: json['sender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
