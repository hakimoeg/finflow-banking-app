// lib/services/chatbot_service.dart — Service chatbot RAG
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'api_service.dart';

class ChatbotService {
  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const Duration _timeout = Duration(seconds: 30); // LLM peut prendre plus de temps

  // Envoie un message au chatbot RAG et retourne la réponse
  Future<String> sendMessage({
    required String message,
    required String token,
    required List<ChatMessage> history,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chatbot/message');

    // Construire l'historique de conversation (sauf les messages de chargement)
    final conversationHistory = history
        .where((m) => !m.isLoading)
        .map((m) => m.toJson())
        .toList();

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'conversationHistory': conversationHistory,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String;
      } else if (response.statusCode == 401) {
        throw ApiException(statusCode: 401, message: 'Session expirée.');
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: data['error'] as String? ?? 'Erreur chatbot.',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Le chatbot est temporairement indisponible.',
      );
    }
  }
}
