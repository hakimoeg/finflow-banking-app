// lib/screens/chatbot_screen.dart — Interface du chatbot bancaire RAG
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chatbot_service.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  // Suggestions de questions rapides
  static const List<String> _quickQuestions = [
    'Quelle est ma dernière transaction ?',
    'Combien de comptes ai-je ?',
    'Quel est mon solde total ?',
    'Montre-moi le solde de chaque compte',
    'Quelles sont mes 5 dernières dépenses ?',
    'Quel est mon plus gros crédit récent ?',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      role: 'assistant',
      content: 'Bonjour ! Je suis **FinBot**, votre assistant bancaire.\n\nJe peux répondre à vos questions sur vos comptes, transactions et soldes en temps réel. Comment puis-je vous aider ?',
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    _inputCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(ChatMessage(role: 'assistant', content: '', isLoading: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Envoyer au backend RAG (exclure le message de chargement)
      final historyToSend = _messages
          .where((m) => !m.isLoading)
          .toList()
        ..removeLast(); // Enlever le dernier message user (envoyé séparément)

      final reply = await _chatbotService.sendMessage(
        message: text,
        token: token,
        history: historyToSend,
      );

      setState(() {
        _messages.removeLast(); // Enlever le message de chargement
        _messages.add(ChatMessage(role: 'assistant', content: reply));
        _isSending = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          role: 'assistant',
          content: '⚠️ ${e.message}',
        ));
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 16, color: Color(0xFFC9A84C))),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FinBot', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C983), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Assistant bancaire IA', style: TextStyle(color: Color(0xFF8892A4), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
      ),
      body: Column(
        children: [
          // ── Liste des messages ─────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                // Afficher les suggestions après le premier message bot
                final showSuggestions = i == 0;
                return Column(
                  children: [
                    _buildMessageBubble(msg),
                    if (showSuggestions) _buildQuickSuggestions(),
                  ],
                );
              },
            ),
          ),

          // ── Zone de saisie ─────────────────────────────────
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('◈', style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C)))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFC9A84C).withOpacity(0.15) : const Color(0xFF141D2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFFC9A84C).withOpacity(0.3) : const Color(0xFF1E2D45),
                ),
              ),
              child: msg.isLoading
                  ? _buildTypingIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageText(msg.content, isUser),
                        const SizedBox(height: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF8892A4))),
                      ],
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isUser) {
    // Parsing simple du markdown (**bold**)
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.w600 : FontWeight.normal,
          color: isUser ? const Color(0xFFE8C97A) : Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _AnimatedDot(delay: i * 200)),
    );
  }

  Widget _buildQuickSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _quickQuestions.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _sendMessage(_quickQuestions[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141D2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: Text(
                _quickQuestions[i],
                style: const TextStyle(fontSize: 12, color: Color(0xFF8892A4)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF141D2E),
        border: Border(top: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              onSubmitted: _isSending ? null : _sendMessage,
              decoration: InputDecoration(
                hintText: 'Posez une question sur vos comptes...',
                hintStyle: const TextStyle(color: Color(0xFF8892A4), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0D1526),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFC9A84C)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? const Color(0xFF1E2D45)
                    : const Color(0xFFC9A84C),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8892A4)),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Color(0xFF0A0F1E), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de l'indicateur de frappe animé
class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(color: Color(0xFF8892A4), shape: BoxShape.circle),
      ),
    ),
  );
}
