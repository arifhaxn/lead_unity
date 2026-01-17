import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:link_unity/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

class ChatbotService {
  // OpenRouter API endpoint and key
  static const String _openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _apiKey =
      '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';

  // System prompt for the AI chatbot
  static const String _systemPrompt =
      '''You are an advanced AI chatbot designed to hold natural, helpful, and intelligent conversations with users.

Core Role:
- Act as a knowledgeable, friendly, and context-aware conversational assistant.
- Adapt your tone based on the user's style (casual, professional, technical).
- Ask clarifying questions when user intent is ambiguous.

Knowledge & Reasoning:
- Use up-to-date general knowledge about AI, technology, business, and everyday topics.
- Break down complex concepts into simple explanations when needed.
- Provide step-by-step reasoning for problem-solving tasks.

Conversation Rules:
- Be concise by default, but expand when the user asks for depth.
- Avoid unnecessary disclaimers or self-references.
- Maintain conversation memory within the session and refer back to prior messages.

User Experience:
- Be proactive: suggest helpful next steps, ideas, or improvements.
- If the user asks to create, improve, or analyze something, guide them efficiently.

Goal: Deliver high-quality, accurate, and engaging responses that make the user feel they are chatting with a capable AI assistant—not a generic bot.''';

  static const String _uuid = 'uuid';

  /// Send a message to the AI chatbot and get a response
  Future<ChatMessage> sendMessage(
      String userMessage, List<ChatMessage> conversationHistory) async {
    try {
      // Build the messages list for the API
      final List<Map<String, String>> messages = [];

      // Add conversation history
      for (var msg in conversationHistory) {
        messages.add({
          'role': msg.sender == 'user' ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      // Add the current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Make the API request
      final response = await http.post(
        Uri.parse(_openRouterBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://lead-unity.app',
          'X-Title': 'LeadUnity Chatbot',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            ...messages,
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final assistantMessage =
            jsonResponse['choices'][0]['message']['content'] as String;

        // Create and return the assistant message
        return ChatMessage(
          id: const Uuid().v4(),
          content: assistantMessage,
          sender: 'assistant',
          timestamp: DateTime.now(),
        );
      } else {
        // Handle error response
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error']?['message'] ??
              'Failed to get response from AI chatbot',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with chatbot: $e');
    }
  }
}
