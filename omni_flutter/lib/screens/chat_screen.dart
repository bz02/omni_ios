import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_models.dart';
import '../services/gemini_service.dart';  
import '../config/app_config.dart';
import '../providers/app_state.dart';
import '../core/theme/modern_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _remainingMessages = 3;
  late final GeminiService _geminiService;
  bool _isLoading = false;
  ChatMode _selectedMode = ChatMode.cosmicGuide;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(apiKey: AppConfig.geminiApiKey);
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        content:
            'Hello! I\'m your AI guide. How can I help you regarding your pet or spirit journey today?',
        isUser: false,
      ));
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty || _remainingMessages == 0) return;

    final userText = _controller.text;
    setState(() {
      _messages.add(ChatMessage(content: userText, isUser: true));
      _remainingMessages--;
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final appState = context.read<AppState>();
    final userContext = {
      'energyDNA': appState.currentUser?.energyDNA?.type ?? 'Unknown',
      'petName': appState.currentUser?.petName ?? 'None',
      'petType': appState.currentUser?.petType ?? 'Unknown',
      'recentTopics': _getRecentTopics(),
    };

    try {
      final response = await _geminiService.chat(
        message: userText,
        userContext: userContext,
        mode: _selectedMode,
      );

      setState(() {
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'I\'m having trouble connecting right now. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _getRecentTopics() {
    final recentUserMessages = _messages
        .where((m) => m.isUser)
        .take(3)
        .map((m) => m.content)
        .toList();
    return recentUserMessages.join(', ');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.background,
      appBar: AppBar(
        title: Text('Chat', style: ModernTheme.header.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: ModernTheme.textMain),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ModernTheme.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: ModernTheme.secondary)
                          )),
                        ),
                        const SizedBox(width: 12),
                        Text('Thinking...', style: ModernTheme.caption),
                      ],
                    ),
                  );
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: ModernTheme.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                   Expanded(
                    child: TextField(
                      controller: _controller,
                      style: ModernTheme.body.copyWith(color: ModernTheme.textMain),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: ModernTheme.body.copyWith(color: ModernTheme.textSub),
                        filled: true,
                        fillColor: ModernTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _controller.text.isEmpty || _remainingMessages == 0
                            ? ModernTheme.textSub.withOpacity(0.3)
                            : ModernTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(ChatMode mode) {
    switch (mode) {
      case ChatMode.cosmicGuide:
        return Icons.auto_awesome;
      case ChatMode.truthSpeaker:
        return Icons.bolt;
      case ChatMode.soulSister:
        return Icons.favorite;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ModernTheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: ModernTheme.secondary, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? ModernTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: ModernTheme.border),
                boxShadow: isUser ? [
                  BoxShadow(
                    color: ModernTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Text(
                message.content,
                style: ModernTheme.body.copyWith(
                  color: isUser ? Colors.white : ModernTheme.textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
