import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/gemini_service.dart';
import '../core/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAiStatus();
    });
  }

  void _checkAiStatus() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (!provider.aiEnabled) {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': 'AI features are currently disabled. Please enable them in settings.',
        });
      });
    } else if (!provider.hasApiKey) {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': 'Please add your Gemini API key in settings to use chat.',
        });
      });
    } else {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': 'Hello! I am your AI Financial Assistant. Ask me anything about your finances.',
        });
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text;
    if (text.isEmpty) return;

    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (!provider.aiEnabled) {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': 'AI features are disabled. Enable them in settings to chat.',
        });
      });
      return;
    }

    if (!provider.hasApiKey) {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': 'Please add your Gemini API key in settings to use chat.',
        });
      });
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();

    final summary = provider.categoryBreakdown;
    final response = await _geminiService.sendChatMessage(text, summary, provider.apiKey!);

    setState(() {
      _messages.add({'role': 'ai', 'content': response});
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  final isSystem = message['role'] == 'system';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? AppTheme.primary 
                            : (isSystem ? AppTheme.error.withOpacity(0.2) : AppTheme.surface),
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                          bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        message['content']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -4),
                    blurRadius: 32,
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Ask about your finances...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
