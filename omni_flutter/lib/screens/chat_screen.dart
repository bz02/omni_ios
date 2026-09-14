import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/billing/entitlements.dart';
import '../core/theme/modern_theme.dart';
import '../config/app_config.dart';
import '../features/paywall/paywall_screen.dart';
import '../models/chat_models.dart';
import '../services/gemini_service.dart';
import '../state/profile_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final GeminiService _geminiService;
  bool _isLoading = false;
  final ChatMode _selectedMode = ChatMode.cosmicGuide;

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
        content: AppConfig.hasModelAccess
            ? 'I have your chart in front of me — both of them. Ask me '
                'anything about it.'
            : 'Readings are computed on your phone and work offline. The '
                'conversational layer needs a model key, which this build does '
                'not have.',
        isUser: false,
      ));
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;

    // The quota lives in EntitlementsController, not in a field on this
    // widget: a counter held in widget state resets on every app launch, which
    // makes the free tier unlimited in practice.
    final entitlements = context.read<EntitlementsController>();
    final decision = entitlements.check(PremiumFeature.chat);
    if (decision is AccessNeedsUpgrade) {
      await PaywallScreen.show(context, trigger: PremiumFeature.chat);
      return;
    }

    if (!AppConfig.hasModelAccess) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'This build has no model key, so I cannot answer in words. '
              'Your charts, daily reading and oracle all still work — they are '
              'computed on the device.',
          isUser: false,
        ));
      });
      return;
    }

    final userText = _controller.text;
    setState(() {
      _messages.add(ChatMessage(content: userText, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Ground the model in the computed charts rather than a vague persona.
    // This is the difference between a horoscope generator and a reading.
    final blueprint = context.read<ProfileController>().blueprint;
    final userContext = <String, dynamic>{
      if (blueprint != null) ...blueprint.promptContext(),
      'energyDNA': blueprint?.signature ?? 'unknown',
      'recentTopics': _getRecentTopics(),
    };

    try {
      final response = await _geminiService.chat(
        message: userText,
        userContext: userContext,
        mode: _selectedMode,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
        _isLoading = false;
      });
      // Charged only once an answer actually arrived.
      await entitlements.recordUse(PremiumFeature.chat);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          content: 'I am having trouble connecting right now. '
              'That one is on us, so it has not used up a free reading.',
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
            icon: const Icon(Icons.delete_outline, color: ModernTheme.textMain),
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
                          child: const Center(child: SizedBox(
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
            decoration: const BoxDecoration(
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
                        color: _controller.text.isEmpty || _isLoading
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
              child: const Icon(Icons.auto_awesome, color: ModernTheme.secondary, size: 16),
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

}
