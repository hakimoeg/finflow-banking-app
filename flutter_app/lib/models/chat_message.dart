// lib/models/chat_message.dart — Modèle de message du chatbot
class ChatMessage {
  final String role;    // 'user' ou 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isBot  => role == 'assistant';

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}
