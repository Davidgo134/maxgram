
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models_message.dart';
import '../theme/maxgram_theme.dart';
import '../widgets/maxgram_bubble.dart';
import '../widgets/maxgram_message_interaction.dart';
import '../max_protocol/max_repository.dart';

/// Chat conversation screen — now wired to MaxRepository for
/// live message streaming and sending over the MAX protocol.
class MaxgramChatScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final MaxRepository repository;

  const MaxgramChatScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
    required this.repository,
  });

  @override
  State<MaxgramChatScreen> createState() => _MaxgramChatScreenState();
}

class _MaxgramChatScreenState extends State<MaxgramChatScreen> {
  final List<MaxgramMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final Map<String, String> _reactions = {};
  StreamSubscription? _subscription;
  static const Duration _groupWindow = Duration(minutes: 2);
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.messagesStreamFor(widget.chatId).listen((message) {
      setState(() => _messages.add(message));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool _isFirstInGroup(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1];
    final curr = _messages[index];
    return prev.isOutgoing != curr.isOutgoing || curr.timestamp.difference(prev.timestamp) > _groupWindow;
  }

  bool _isLastInGroup(int index) {
    if (index == _messages.length - 1) return true;
    final next = _messages[index + 1];
    final curr = _messages[index];
    return next.isOutgoing != curr.isOutgoing || next.timestamp.difference(curr.timestamp) > _groupWindow;
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    final optimistic = MaxgramMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      isOutgoing: true,
      status: MaxgramMessageStatus.sending,
    );
    setState(() {
      _messages.add(optimistic);
      _inputController.clear();
      _sending = true;
    });

    try {
      await widget.repository.sendMessage(widget.chatId, text);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx != -1) {
          _messages[idx] = MaxgramMessage(
            id: optimistic.id,
            text: optimistic.text,
            timestamp: optimistic.timestamp,
            isOutgoing: true,
            status: MaxgramMessageStatus.sent,
          );
        }
      });
    } catch (_) {
      // Keep message visible with "sending" status to signal failure;
      // a real implementation would show a retry affordance here.
    } finally {
      setState(() => _sending = false);
    }
  }

  void _deleteMessage(String id) {
    setState(() => _messages.removeWhere((m) => m.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: MaxgramColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.chatTitle),
        backgroundColor: MaxgramColors.background.withOpacity(0.94),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text('Нет сообщений', style: TextStyle(color: MaxgramColors.subtitleText)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final bubble = MaxgramBubble(
                          message: msg,
                          isFirstInGroup: _isFirstInGroup(index),
                          isLastInGroup: _isLastInGroup(index),
                        );
                        return Column(
                          crossAxisAlignment: msg.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            MaxgramMessageInteraction(
                              message: msg,
                              onReact: (emoji) => setState(() => _reactions[msg.id] = emoji),
                              onDelete: () => _deleteMessage(msg.id),
                              child: bubble,
                            ),
                            if (_reactions[msg.id] != null)
                              Padding(
                                padding: EdgeInsets.only(left: msg.isOutgoing ? 0 : 24, right: msg.isOutgoing ? 24 : 0, bottom: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: MaxgramColors.secondaryBackground, borderRadius: BorderRadius.circular(12)),
                                  child: Text(_reactions[msg.id]!, style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: MaxgramColors.background,
        border: Border(top: BorderSide(color: MaxgramColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 36, maxHeight: 120),
              decoration: BoxDecoration(color: MaxgramColors.secondaryBackground, borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: CupertinoTextField(
                controller: _inputController,
                placeholder: 'Message',
                maxLines: 5,
                minLines: 1,
                decoration: const BoxDecoration(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: MaxgramColors.accentBlue, shape: BoxShape.circle),
              child: _sending
                  ? const Padding(padding: EdgeInsets.all(8), child: CupertinoActivityIndicator(color: Colors.white))
                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
