import 'package:flutter/material.dart';
import 'package:link_unity/api%20services/chatbot_service.dart';
import 'package:link_unity/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Send a user message and get AI response
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    // Clear previous error
    _errorMessage = null;

    // Add user message to conversation
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: userMessage,
      sender: 'user',
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response
      final assistantMessage = await _chatbotService.sendMessage(
        userMessage,
        _messages,
      );

      // Add assistant message to conversation
      _messages.add(assistantMessage);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // Remove the user message if there was an error
      // Uncomment the next line to remove user message on error
      // _messages.removeWhere((msg) => msg.id == userMsg.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
