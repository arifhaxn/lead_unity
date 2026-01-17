import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:link_unity/chat_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(ChatProvider chatProvider) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _messageController.clear();
      chatProvider.sendMessage(message).then((_) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot Assistant'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear Chat',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Clear Chat'),
                          content: const Text(
                              'Are you sure you want to clear all messages?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                chatProvider.clearMessages();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          return Column(
            children: [
              // Messages List
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Start a conversation!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Ask me anything about your projects,\nideation, or any topic you\'d like to discuss.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          final isUser = message.sender == 'user';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue[100],
                                      child: Icon(
                                        Icons.smart_toy_outlined,
                                        size: 18,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 10.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Colors.blue[600]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isUser
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            color: isUser
                                                ? Colors.blue[100]
                                                : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isUser)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue[100],
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 18,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Error Message Display
              if (chatProvider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatProvider.errorMessage!,
                          style:
                              TextStyle(color: Colors.red[600], fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: chatProvider.clearError,
                        child:
                            Icon(Icons.close, color: Colors.red[600], size: 18),
                      ),
                    ],
                  ),
                ),

              // Loading Indicator
              if (chatProvider.isLoading)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.smart_toy_outlined,
                          size: 18,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[600]!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Typing...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide:
                                BorderSide(color: Colors.blue[600]!, width: 2),
                          ),
                        ),
                        maxLines: null,
                        enabled: !chatProvider.isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.blue[600],
                      onPressed: chatProvider.isLoading
                          ? null
                          : () => _handleSendMessage(chatProvider),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
