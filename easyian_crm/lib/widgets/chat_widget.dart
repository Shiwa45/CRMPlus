import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/utils/api_client.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'content': 'Hello! How can I help you today?'},
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final response = await ApiClient.instance.post(
        '/chatbot/',
        body: {'message': text},
      );
      
      setState(() {
        _messages.add({'role': 'ai', 'content': response['response'] ?? 'No response received.'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'error', 'content': 'Error connecting to chatbot. Please try again later.'});
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildChatWindow() {
    return Container(
      width: 350,
      height: 500,
      margin: const EdgeInsets.only(bottom: 80, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'AI Assistant',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _isOpen = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final isError = message['role'] == 'error';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isError 
                          ? Colors.red.withOpacity(0.1) 
                          : isUser 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).hoverColor,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                      ),
                    ),
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      message['content']!,
                      style: TextStyle(
                        color: isError 
                            ? Colors.red 
                            : isUser 
                                ? Colors.white 
                                : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).hoverColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isOpen) _buildChatWindow(),
          
          if (!_isOpen)
            FloatingActionButton(
              onPressed: () => setState(() => _isOpen = true),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
