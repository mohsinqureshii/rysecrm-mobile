import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/crm_store.dart';
import '../../data/services/auth_provider.dart';
import '../shell/ryse_app_bar.dart';
import 'assistant_engine.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatEntry {
  const _ChatEntry({
    required this.isUser,
    required this.text,
    this.suggestions = const [],
  });

  final bool isUser;
  final String text;
  final List<String> suggestions;
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _messages = [];
  bool _thinking = false;
  bool _greeted = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_greeted) {
      _greeted = true;
      final engine = AssistantEngine(context.read<CrmStore>());
      final name =
          context.read<AuthProvider>().user?.name.split(' ').first ?? 'there';
      final reply = engine.greeting(name);
      _messages.add(_ChatEntry(
        isUser: false,
        text: reply.text,
        suggestions: reply.suggestions,
      ));
    }
  }

  Future<void> _send(String text) async {
    final query = text.trim();
    if (query.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatEntry(isUser: true, text: query));
      _thinking = true;
    });
    _scrollToBottom();

    // Simulated inference latency for a natural feel.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final engine = AssistantEngine(context.read<CrmStore>());
    final reply = engine.answer(query);
    setState(() {
      _messages.add(_ChatEntry(
        isUser: false,
        text: reply.text,
        suggestions: reply.suggestions,
      ));
      _thinking = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildRyseAppBar(context, title: 'RYSE AI'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(
                  entry: _messages[index],
                  onSuggestionTap: _send,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your pipeline, deals, leads…',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: AppColors.aiGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _send(_controller.text),
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
  const _MessageBubble({required this.entry, required this.onSuggestionTap});

  final _ChatEntry entry;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.isUser;
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.aiGradient),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.brand : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border:
                      isUser ? null : Border.all(color: AppColors.border),
                ),
                child: Text(
                  entry.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (entry.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 38, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in entry.suggestions)
                  ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ai,
                      ),
                    ),
                    side: BorderSide(
                      color: AppColors.ai.withValues(alpha: 0.4),
                    ),
                    backgroundColor: AppColors.ai.withValues(alpha: 0.06),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.aiGradient),
            borderRadius: BorderRadius.circular(9),
          ),
          child:
              const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Opacity(
                      opacity: 0.3 +
                          0.7 *
                              ((_controller.value + i / 3) % 1.0 < 0.5
                                  ? ((_controller.value + i / 3) % 1.0) * 2
                                  : (1 - (_controller.value + i / 3) % 1.0) *
                                      2),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.ai,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
