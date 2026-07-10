
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_message.dart';
import '../theme/maxgram_theme.dart';

/// Wraps MaxgramBubble with Telegram-style interactions:
/// - double tap -> quick reaction (default emoji, animated pop)
/// - long press -> context menu with emoji strip + actions
///   (Reply, Copy, Forward, Delete), mirroring ContextController.swift
class MaxgramMessageInteraction extends StatefulWidget {
  final Widget child;
  final MaxgramMessage message;
  final String defaultReaction;
  final void Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;

  const MaxgramMessageInteraction({
    super.key,
    required this.child,
    required this.message,
    this.defaultReaction = '👍',
    this.onReact,
    this.onReply,
    this.onCopy,
    this.onForward,
    this.onDelete,
  });

  @override
  State<MaxgramMessageInteraction> createState() => _MaxgramMessageInteractionState();
}

class _MaxgramMessageInteractionState extends State<MaxgramMessageInteraction>
    with SingleTickerProviderStateMixin {
  String? _floatingReaction;
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  static const List<String> _quickEmojis = ['👍', '❤️', '🔥', '😂', '😮', '😢', '🙏'];

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(_popController);
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _triggerReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() => _floatingReaction = emoji);
    _popController.forward(from: 0);
    widget.onReact?.call(emoji);
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ContextMenuOverlay(
        anchor: globalPosition,
        quickEmojis: _quickEmojis,
        isOutgoing: widget.message.isOutgoing,
        onEmojiSelected: (emoji) {
          entry.remove();
          _triggerReaction(emoji);
        },
        onAction: (action) {
          entry.remove();
          switch (action) {
            case _MenuAction.reply:
              widget.onReply?.call();
              break;
            case _MenuAction.copy:
              Clipboard.setData(ClipboardData(text: widget.message.text));
              widget.onCopy?.call();
              break;
            case _MenuAction.forward:
              widget.onForward?.call();
              break;
            case _MenuAction.delete:
              widget.onDelete?.call();
              break;
          }
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _triggerReaction(widget.defaultReaction),
      onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: widget.message.isOutgoing ? Alignment.topRight : Alignment.topLeft,
        children: [
          widget.child,
          if (_floatingReaction != null)
            Positioned(
              top: -18,
              right: widget.message.isOutgoing ? 12 : null,
              left: widget.message.isOutgoing ? null : 12,
              child: ScaleTransition(
                scale: _popScale,
                child: Text(_floatingReaction!, style: TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}

enum _MenuAction { reply, copy, forward, delete }

/// Full-screen overlay: dimmed backdrop + emoji strip above the tapped
/// bubble + action list below, mirroring Telegram-iOS ContextController.
class _ContextMenuOverlay extends StatefulWidget {
  final Offset anchor;
  final List<String> quickEmojis;
  final bool isOutgoing;
  final void Function(String emoji) onEmojiSelected;
  final void Function(_MenuAction action) onAction;
  final VoidCallback onDismiss;

  const _ContextMenuOverlay({
    required this.anchor,
    required this.quickEmojis,
    required this.isOutgoing,
    required this.onEmojiSelected,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = 200.0;
    double left = widget.isOutgoing ? widget.anchor.dx - menuWidth : widget.anchor.dx;
    left = left.clamp(12.0, screenWidth - menuWidth - 12.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: FadeTransition(
              opacity: _controller,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: (widget.anchor.dy - 90).clamp(60.0, double.infinity),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            alignment: widget.isOutgoing ? Alignment.bottomRight : Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.quickEmojis
                        .map((e) => GestureDetector(
                              onTap: () => widget.onEmojiSelected(e),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(e, style: TextStyle(fontSize: 24)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _menuItem('Reply', Icons.reply, () => widget.onAction(_MenuAction.reply)),
                      Divider(height: 1, color: MaxgramColors.separator),
                      _menuItem('Copy', Icons.copy, () => widget.onAction(_MenuAction.copy)),
                      Divider(height: 1, color: MaxgramColors.separator),
                      _menuItem('Forward', Icons.forward, () => widget.onAction(_MenuAction.forward)),
                      Divider(height: 1, color: MaxgramColors.separator),
                      _menuItem('Delete', Icons.delete, () => widget.onAction(_MenuAction.delete), isDestructive: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? MaxgramColors.swipeDelete : MaxgramColors.titleText;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 16)),
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
