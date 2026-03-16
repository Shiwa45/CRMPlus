// widgets/ai_assistant_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/api_client.dart';

class AIAssistantWidget extends StatefulWidget {
  const AIAssistantWidget({super.key});

  @override
  State<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends State<AIAssistantWidget>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _anim;
  late Animation<double> _scale;
  final List<Map<String, String>> _messages = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    // Welcome message
    _messages.add({'role': 'assistant',
        'content': "Hello! I'm your AI CRM assistant powered by Gemini.\n\n"
            "I can help you:\n• Score and prioritise leads\n• Draft emails\n"
            "• Analyse your pipeline\n• Generate marketing copy\n\nHow can I help?"});
  }

  @override
  void dispose() { _anim.dispose(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _anim.forward(); else _anim.reverse();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _thinking = true;
    });
    _scrollDown();
    try {
      final history = _messages.take(_messages.length - 1)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();
      final result = await ApiClient.instance.post(AppConstants.aiChatEndpoint, body: {
        'message': msg,
        'history': history,
        'crm_context': 'User is a sales team member',
      });
      final reply = result['reply'] as String? ?? 'No response from AI.';
      if (mounted) setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _thinking = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _messages.add({'role': 'assistant',
            'content': 'Sorry, AI assistant is unavailable. Please check your Gemini API key in Settings.'});
        _thinking = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(alignment: Alignment.bottomRight, children: [
      // Chat panel
      if (_open) ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomRight,
        child: Container(
          width: 360, height: 500,
          margin: const EdgeInsets.only(bottom: 72, right: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.2), blurRadius: 24,
              offset: const Offset(0, 8),
            )],
          ),
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Assistant', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Powered by Gemini', style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ]),
                const Spacer(),
                // Quick action chips
                _quickChip('Score Leads', () => _quickSend('Score my top leads and rank them')),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: _toggle,
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
            ),
            // Messages
            Expanded(child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _ThinkingBubble(isDark: isDark);
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return _MessageBubble(
                  text: m['content']!, isUser: isUser, isDark: isDark,
                );
              },
            )),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder2)),
              ),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.inter(fontSize: 13),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your CRM...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBg : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
      // FAB
      Positioned(
        bottom: 16, right: 16,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 6),
              )],
            ),
            child: Center(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(_open ? Icons.close : Icons.auto_awesome,
                  key: ValueKey(_open), color: Colors.white, size: 24),
            )),
          ),
        ),
      ),
    ]);
  }

  Widget _quickChip(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white,
          fontWeight: FontWeight.w600)),
    ),
  );

  void _quickSend(String msg) {
    _ctrl.text = msg;
    _send();
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser, isDark;
  const _MessageBubble({required this.text, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF7C3AED)
              : (isDark ? AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(text, style: GoogleFonts.inter(
            fontSize: 13, height: 1.4,
            color: isUser ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText))),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  final bool isDark;
  const _ThinkingBubble({required this.isDark});
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerLeft, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14),
            bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 0; i < 3; i++) AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Container(
            width: 7, height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(
                  0.3 + (_ctrl.value * 0.7 * (i == 1 ? 1 : i == 0 ? 0.7 : 0.5))),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ]),
    ));
  }
}
